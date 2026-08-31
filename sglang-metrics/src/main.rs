// sglang-usage: persist SGLang /metrics across sessions.
//
// `scrape` runs from a systemd timer. It pulls /metrics from each
// endpoint and appends TSV lines to a data file. The file grows
// across SGLang restarts, so usage accumulates forever. `report`
// and `sessions` aggregate the file: token totals, request counts,
// cached tokens, session counts, and the estimated cloud API cost
// that local serving saved.
//
// Standard library only. No crates.

use std::collections::{BTreeMap, HashSet};
use std::fs::File;
use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const DEFAULT_DB: &str = "/var/lib/sglang-metrics/usage.tsv";

const DEFAULT_METRICS: [&str; 7] = [
    "sglang:prompt_tokens_total",
    "sglang:generation_tokens_total",
    "sglang:num_requests_total",
    "sglang:cached_tokens_total",
    "sglang:realtime_tokens_total",
    "sglang:backuped_tokens_total",
    "sglang:cache_hit_rate",
];

const M_PROMPT: &str = "sglang:prompt_tokens_total";
const M_GEN: &str = "sglang:generation_tokens_total";
const M_REQ: &str = "sglang:num_requests_total";
const M_CACHED: &str = "sglang:cached_tokens_total";
const M_HIT: &str = "sglang:cache_hit_rate";

struct Sample {
    name: String,
    labels: String,
    value: f64,
    kind: String,
}

fn default_metrics() -> Vec<String> {
    DEFAULT_METRICS.iter().map(|s| s.to_string()).collect()
}

// ---------- flags ----------

fn collect<'a>(args: &[&'a str], key: &str) -> Vec<&'a str> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < args.len() {
        if args[i] == key {
            if i + 1 < args.len() {
                out.push(args[i + 1]);
            }
            i += 2;
        } else {
            i += 1;
        }
    }
    out
}

fn opt<'a>(args: &[&'a str], key: &str) -> Option<&'a str> {
    collect(args, key).into_iter().next()
}

fn parse_endpoint(arg: &str) -> Result<(String, String, u16), String> {
    let hostport = match arg.split_once('=') {
        Some((_, hp)) => hp.to_string(),
        None => arg.to_string(),
    };
    let (host, port) = match hostport.rsplit_once(':') {
        Some((h, p)) => {
            let port: u16 = p.parse().map_err(|_| format!("bad port in {arg}"))?;
            (h.to_string(), port)
        }
        None => (hostport.clone(), 80),
    };
    let name = match arg.split_once('=') {
        Some((n, _)) => n.to_string(),
        None => hostport,
    };
    Ok((name, host, port))
}

// ---------- HTTP (std only) ----------

fn http_metrics(host: &str, port: u16, timeout: Duration) -> Result<String, String> {
    let addr = format!("{host}:{port}");
    let addrs = addr
        .to_socket_addrs()
        .map_err(|e| format!("resolve {addr}: {e}"))?;
    let mut last_err = "connect failed".to_string();
    let mut stream: Option<TcpStream> = None;
    for a in addrs {
        match TcpStream::connect_timeout(&a, timeout) {
            Ok(s) => {
                stream = Some(s);
                break;
            }
            Err(e) => last_err = e.to_string(),
        }
    }
    let mut stream = stream.ok_or_else(|| last_err.clone())?;
    let _ = stream.set_read_timeout(Some(timeout));
    let req = format!(
        "GET /metrics HTTP/1.1\r\nHost: {addr}\r\nUser-Agent: sglang-usage\r\nAccept: text/plain\r\nConnection: close\r\n\r\n"
    );
    stream
        .write_all(req.as_bytes())
        .map_err(|e| e.to_string())?;
    let mut buf = Vec::new();
    stream.read_to_end(&mut buf).map_err(|e| e.to_string())?;
    parse_response(&buf)
}

fn parse_response(buf: &[u8]) -> Result<String, String> {
    let idx = buf
        .windows(4)
        .position(|w| w == b"\r\n\r\n")
        .ok_or("short HTTP response")?;
    let head = String::from_utf8_lossy(&buf[..idx]);
    let mut lines = head.lines();
    let status = lines.next().ok_or("empty HTTP response")?;
    let code: u16 = status
        .split(' ')
        .nth(1)
        .and_then(|c| c.parse().ok())
        .ok_or("bad HTTP status line")?;
    if code != 200 {
        return Err(format!("HTTP {code}"));
    }
    let mut content_length: Option<usize> = None;
    let mut chunked = false;
    for l in lines {
        let l = l.to_ascii_lowercase();
        if let Some(v) = l.strip_prefix("content-length:") {
            content_length = v.trim().parse().ok();
        }
        if l.starts_with("transfer-encoding:") && l.contains("chunked") {
            chunked = true;
        }
    }
    let body = &buf[idx + 4..];
    let text = if chunked {
        decode_chunked(body)
    } else if let Some(cl) = content_length {
        String::from_utf8_lossy(&body[..body.len().min(cl)]).into_owned()
    } else {
        String::from_utf8_lossy(body).into_owned()
    };
    if text.is_empty() {
        return Err("empty body".to_string());
    }
    Ok(text)
}

fn decode_chunked(mut b: &[u8]) -> String {
    let mut out = String::new();
    loop {
        let nl = match b.windows(2).position(|w| w == b"\r\n") {
            Some(p) => p,
            None => break,
        };
        let size_str = String::from_utf8_lossy(&b[..nl]);
        let hex = size_str.split(';').next().unwrap_or("").trim();
        let size: u64 = u64::from_str_radix(hex, 16).unwrap_or(0);
        if size == 0 {
            break;
        }
        let start = nl + 2;
        if b.len() < start + size as usize {
            break;
        }
        out.push_str(&String::from_utf8_lossy(&b[start..start + size as usize]));
        b = &b[start + size as usize + 2..];
    }
    out
}

// ---------- Prometheus text parsing ----------

fn canonical_labels(raw: &str) -> String {
    if raw.is_empty() {
        return String::new();
    }
    // Split on commas that sit outside of quotes.
    let cs: Vec<(usize, char)> = raw.char_indices().collect();
    let mut inq = false;
    let mut start: Option<usize> = None;
    let mut parts: Vec<&str> = Vec::new();
    for (off, c) in &cs {
        match c {
            '"' => inq = !inq,
            ',' if !inq => {
                if let Some(s) = start {
                    parts.push(&raw[s..*off]);
                    start = None;
                }
            }
            _ if !inq && start.is_none() => {
                if !c.is_whitespace() {
                    start = Some(*off);
                }
            }
            _ => {}
        }
    }
    if let Some(s) = start {
        parts.push(&raw[s..]);
    }
    let mut pairs: Vec<(String, String)> = Vec::new();
    for p in parts {
        let p = p.trim();
        if p.is_empty() {
            continue;
        }
        if let Some(eq) = p.find('=') {
            let key = p[..eq].trim().to_string();
            let val = p[eq + 1..].trim();
            let val = val.trim_matches('"');
            let val = val.replace("\\\"", "\"").replace("\\\\", "\\");
            pairs.push((key, val.to_string()));
        }
    }
    pairs.sort();
    let mut out = String::new();
    for (k, v) in &pairs {
        out.push_str(&format!("{k}=\"{v}\","));
    }
    out.pop();
    out
}

fn parse_exposition(text: &str, wanted: &HashSet<String>) -> Vec<Sample> {
    let mut kinds: BTreeMap<&str, &str> = BTreeMap::new();
    let mut out: Vec<Sample> = Vec::new();
    for line in text.lines() {
        let t = line.trim_end();
        if t.starts_with('#') {
            if let Some(rest) = t.strip_prefix("# TYPE") {
                let mut it = rest.split_whitespace();
                if let (Some(nm), Some(k)) = (it.next(), it.next()) {
                    kinds.insert(nm, k);
                }
            }
            continue;
        }
        if t.is_empty() {
            continue;
        }
        let sp = match t.rfind(' ') {
            Some(p) => p,
            None => continue,
        };
        let name_part = &t[..sp];
        let value_s = &t[sp + 1..];
        let (name, labels_raw) = match name_part.find('{') {
            Some(p) => {
                let end = if name_part.ends_with('}') {
                    name_part.len() - 1
                } else {
                    name_part.len()
                };
                (&name_part[..p], &name_part[p + 1..end])
            }
            None => (name_part, ""),
        };
        if name.ends_with("_created") || name.ends_with("_time") || name.ends_with("_bucket") {
            continue;
        }
        if !wanted.contains(name) {
            continue;
        }
        let value: f64 = match value_s.parse::<f64>() {
            Ok(v) if v.is_finite() => v,
            _ => continue,
        };
        let labels = canonical_labels(labels_raw);
        let kind = kinds
            .get(name)
            .copied()
            .unwrap_or(if name.ends_with("_total") {
                "counter"
            } else {
                "gauge"
            })
            .to_string();
        out.push(Sample {
            name: name.to_string(),
            labels,
            value,
            kind,
        });
    }
    out
}

// ---------- data file ----------

type SeriesMap = BTreeMap<String, Vec<(f64, String, String, f64, String)>>;
type MetaMap = BTreeMap<String, (f64, f64, u64, String)>;

fn load_db(path: &str) -> Result<(SeriesMap, MetaMap), String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("cannot read {path}: {e}"))?;
    let mut rows: SeriesMap = BTreeMap::new();
    let mut meta: MetaMap = BTreeMap::new();
    for line in text.lines() {
        let mut f = line.split('\t');
        let rec = match f.next() {
            Some(r) => r,
            None => continue,
        };
        match rec {
            "S" => {
                let ts: f64 = f.next().and_then(|x| x.parse().ok()).unwrap_or(0.0);
                let ep = f.next().unwrap_or("");
                let status = f.next().unwrap_or("");
                let _detail = f.next().unwrap_or("");
                if ep.is_empty() {
                    continue;
                }
                let m = meta.entry(ep.to_string()).or_insert((f64::MAX, 0.0, 0u64, String::new()));
                m.0 = m.0.min(ts);
                m.1 = m.1.max(ts);
                m.2 += 1;
                m.3 = status.to_string();
            }
            "X" => {
                let ts: f64 = f.next().and_then(|x| x.parse().ok()).unwrap_or(0.0);
                let ep = f.next().unwrap_or("");
                let name = f.next().unwrap_or("");
                let labels = f.next().unwrap_or("");
                let value: f64 = f.next().and_then(|x| x.parse().ok()).unwrap_or(0.0);
                let kind = f.next().unwrap_or("gauge");
                if ep.is_empty() || name.is_empty() {
                    continue;
                }
                rows.entry(ep.to_string())
                    .or_default()
                    .push((ts, name.to_string(), labels.to_string(), value, kind.to_string()));
            }
            _ => {}
        }
    }
    Ok((rows, meta))
}

// ---------- session detection and totals ----------

struct Window {
    start: Option<f64>,
    end: Option<f64>,
    totals: BTreeMap<String, f64>,
}

struct EpSummary {
    endpoint: String,
    first_ts: Option<f64>,
    last_ts: Option<f64>,
    scrape_count: u64,
    last_status: String,
    session_count: usize,
    sessions: Vec<Window>,
    grand: BTreeMap<String, f64>,
    hit_avg: Option<f64>,
    hit_latest: Option<f64>,
    est_cost: f64,
}

fn endpoint_summary(
    ep: &str,
    rows: &[(f64, String, String, f64, String)],
    wanted: &[String],
    meta: Option<&(f64, f64, u64, String)>,
    input_price: f64,
    output_price: f64,
) -> EpSummary {
    let mut series: BTreeMap<(String, String), (Vec<f64>, Vec<f64>, String)> = BTreeMap::new();
    for (ts, name, labels, value, kind) in rows {
        let e = series
            .entry((name.clone(), labels.clone()))
            .or_insert_with(|| (Vec::new(), Vec::new(), kind.clone()));
        e.0.push(*ts);
        e.1.push(*value);
    }
    if series.is_empty() {
        return EpSummary {
            endpoint: ep.to_string(),
            first_ts: meta.map(|m| m.0),
            last_ts: meta.map(|m| m.1),
            scrape_count: meta.map(|m| m.2).unwrap_or(0),
            last_status: meta.map(|m| m.3.clone()).unwrap_or_default(),
            session_count: 0,
            sessions: Vec::new(),
            grand: BTreeMap::new(),
            hit_avg: None,
            hit_latest: None,
            est_cost: 0.0,
        };
    }
    // A counter dropping means the engine restarted and the counter
    // started over. Each such drop marks a session boundary.
    let mut bounds: Vec<f64> = Vec::new();
    for ((_, _), (ts, vals, kind)) in &series {
        if kind != "counter" {
            continue;
        }
        for i in 1..ts.len() {
            if vals[i] < vals[i - 1] - 1e-9 {
                bounds.push(ts[i]);
            }
        }
    }
    bounds.sort_by(|a, b| a.partial_cmp(b).unwrap());
    bounds.dedup_by(|a, b| *a == *b);
    let mut windows: Vec<(Option<f64>, Option<f64>)> = Vec::new();
    let mut prev: Option<f64> = None;
    for b in &bounds {
        windows.push((prev, Some(*b)));
        prev = Some(*b);
    }
    windows.push((prev, None));

    let mut sessions: Vec<Window> = Vec::new();
    let mut grand: BTreeMap<String, f64> = BTreeMap::new();
    for (ws, we) in &windows {
        let mut tot: BTreeMap<String, f64> = BTreeMap::new();
        for ((name, _), (ts, vals, _)) in &series {
            if !wanted.iter().any(|m| m == name) {
                continue;
            }
            let mut last: Option<f64> = None;
            for i in 0..ts.len() {
                if ts[i] >= ws.unwrap_or(f64::MIN) && (we.is_none() || ts[i] < we.unwrap()) {
                    last = Some(vals[i]);
                }
            }
            if let Some(v) = last {
                *tot.entry(name.clone()).or_insert(0.0) += v;
            }
        }
        for (k, v) in &tot {
            *grand.entry(k.clone()).or_insert(0.0) += v;
        }
        sessions.push(Window {
            start: *ws,
            end: *we,
            totals: tot,
        });
    }

    let mut hits: Vec<f64> = Vec::new();
    for (_, name, _, value, _) in rows {
        if name == M_HIT {
            hits.push(*value);
        }
    }

    let prompt = grand.get(M_PROMPT).copied().unwrap_or(0.0);
    let gen = grand.get(M_GEN).copied().unwrap_or(0.0);
    let est_cost = prompt / 1e6 * input_price + gen / 1e6 * output_price;

    EpSummary {
        endpoint: ep.to_string(),
        first_ts: meta.map(|m| m.0),
        last_ts: meta.map(|m| m.1),
        scrape_count: meta.map(|m| m.2).unwrap_or(0),
        last_status: meta.map(|m| m.3.clone()).unwrap_or_default(),
        session_count: sessions.len(),
        sessions,
        grand,
        hit_avg: if hits.is_empty() {
            None
        } else {
            Some(hits.iter().sum::<f64>() / hits.len() as f64)
        },
        hit_latest: hits.last().copied(),
        est_cost,
    }
}

// ---------- formatting ----------

fn iso_utc(ts: f64) -> String {
    let secs = ts as i64;
    let days = secs.div_euclid(86400);
    let rem = secs.rem_euclid(86400);
    let (y, mo, d) = civil_from_days(days);
    format!(
        "{:04}-{:02}-{:02} {:02}:{:02} UTC",
        y,
        mo,
        d,
        rem / 3600,
        (rem % 3600) / 60
    )
}

fn civil_from_days(z0: i64) -> (i64, u32, u32) {
    // Howard Hinnant's civil calendar algorithm.
    let z = z0 + 719468;
    let era = if z >= 0 { z } else { z - 146096 } / 146097;
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 536288) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let m = (5 * doy + 2) / 153;
    let d = doy - (153 * m + 2) / 5 + 1;
    let m = if m < 10 { m + 3 } else { m - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    (y, m as u32, d as u32)
}

fn fmt_ts(ts: Option<f64>) -> String {
    match ts {
        Some(v) => iso_utc(v),
        None => "ongoing".to_string(),
    }
}

fn fmt_int(v: f64) -> String {
    let i = v.round() as i64;
    let neg = i < 0;
    let d = i.abs().to_string();
    let cs: Vec<char> = d.chars().collect();
    let mut out = String::new();
    for (idx, c) in cs.iter().enumerate() {
        if idx > 0 && (cs.len() - idx) % 3 == 0 {
            out.push(',');
        }
        out.push(*c);
    }
    if neg {
        format!("-{out}")
    } else {
        out
    }
}

fn jesc(s: &str) -> String {
    let mut out = String::new();
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            _ => out.push(c),
        }
    }
    out
}

// ---------- subcommands ----------

fn cmd_scrape(args: &[&str]) -> i32 {
    let db = opt(args, "--db").unwrap_or(DEFAULT_DB);
    let timeout_s: f64 = opt(args, "--timeout")
        .and_then(|s| s.parse().ok())
        .unwrap_or(10.0);
    let metrics: Vec<String> = match opt(args, "--metrics") {
        Some(m) => m.split(',').map(|x| x.trim().to_string()).filter(|x| !x.is_empty()).collect(),
        None => default_metrics(),
    };
    let eps = collect(args, "--endpoint");
    if eps.is_empty() {
        eprintln!("scrape: give --endpoint HOST:PORT (repeatable)");
        return 2;
    }
    let wanted: HashSet<String> = metrics.iter().cloned().collect();
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0);
    let mut file = match File::options().create(true).append(true).open(db) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("scrape: cannot open {db}: {e}");
            return 1;
        }
    };
    let mut ok_count = 0usize;
    for ep in &eps {
        let (name, host, port) = match parse_endpoint(ep) {
            Ok(t) => t,
            Err(e) => {
                eprintln!("scrape: {e}");
                continue;
            }
        };
        match http_metrics(&host, port, Duration::from_secs_f64(timeout_s)) {
            Ok(body) => {
                let samples = parse_exposition(&body, &wanted);
                if writeln!(file, "S\t{now}\t{name}\tok\t{} samples", samples.len()).is_err()
                    || samples
                        .iter()
                        .any(|s| {
                            writeln!(
                                file,
                                "X\t{now}\t{name}\t{}\t{}\t{}\t{}",
                                s.name, s.labels, s.value, s.kind
                            )
                            .is_err()
                        })
                {
                    eprintln!("scrape: write to {db} failed");
                    continue;
                }
                println!("[sglang-usage] {name}: ok ({} samples)", samples.len());
                ok_count += 1;
            }
            Err(e) => {
                let detail = e.replace('\t', " ").replace('\n', " ");
                let _ = writeln!(file, "S\t{now}\t{name}\tdown\t{detail}");
                eprintln!("[sglang-usage] {name}: DOWN ({e})");
            }
        }
    }
    let _ = file.flush();
    if ok_count == 0 {
        1
    } else {
        0
    }
}

fn run_report_and_sessions(args: &[&str], sessions_only: bool) -> i32 {
    let db = opt(args, "--db").unwrap_or(DEFAULT_DB);
    let input_price: f64 = opt(args, "--input-price").and_then(|s| s.parse().ok()).unwrap_or(3.0);
    let output_price: f64 = opt(args, "--output-price").and_then(|s| s.parse().ok()).unwrap_or(15.0);
    let as_json = args.iter().any(|a| *a == "--json");
    let metrics: Vec<String> = match opt(args, "--metrics") {
        Some(m) => m.split(',').map(|x| x.trim().to_string()).filter(|x| !x.is_empty()).collect(),
        None => default_metrics(),
    };
    let (rows, meta) = match load_db(db) {
        Ok(d) => d,
        Err(e) => {
            eprintln!("report: {e}");
            return 1;
        }
    };
    let mut eps: Vec<String> = rows.keys().cloned().collect();
    for ep in meta.keys() {
        if !eps.iter().any(|e| e == ep) {
            eps.push(ep.clone());
        }
    }
    eps.sort();
    if eps.is_empty() {
        eprintln!("report: no data in {db}");
        return 1;
    }
    let mut summaries: Vec<EpSummary> = Vec::new();
    for ep in &eps {
        let r = match rows.get(ep) {
            Some(r) => r,
            None => &Vec::new(),
        };
        summaries.push(endpoint_summary(ep, r, &metrics, meta.get(ep), input_price, output_price));
    }
    if as_json {
        print!("{}", json_report(&summaries));
        return 0;
    }
    if sessions_only {
        for r in &summaries {
            println!("Endpoint {}: {} session(s)", r.endpoint, r.session_count);
            if r.session_count == 0 {
                println!("  no samples yet (last scrape {})", r.last_status);
                continue;
            }
            for (i, s) in r.sessions.iter().enumerate() {
                let start = match s.start {
                    Some(v) => format!("{} ", iso_utc(v)),
                    None => "db start  ".to_string(),
                };
                let end = match s.end {
                    Some(v) => iso_utc(v),
                    None => "ongoing".to_string(),
                };
                println!("  {}: {}-> {}", i + 1, start, end);
                println!(
                    "     prompt={} gen={} reqs={} cached={}",
                    fmt_int(s.totals.get(M_PROMPT).copied().unwrap_or(0.0)),
                    fmt_int(s.totals.get(M_GEN).copied().unwrap_or(0.0)),
                    fmt_int(s.totals.get(M_REQ).copied().unwrap_or(0.0)),
                    fmt_int(s.totals.get(M_CACHED).copied().unwrap_or(0.0))
                );
            }
        }
        return 0;
    }
    println!("SGLang usage report (db: {db})\n");
    for r in &summaries {
        let prompt = r.grand.get(M_PROMPT).copied().unwrap_or(0.0);
        let gen = r.grand.get(M_GEN).copied().unwrap_or(0.0);
        let reqs = r.grand.get(M_REQ).copied().unwrap_or(0.0);
        let cached = r.grand.get(M_CACHED).copied().unwrap_or(0.0);
        println!("Endpoint {}", r.endpoint);
        if r.session_count == 0 {
            println!("  no samples yet (last scrape {})", r.last_status);
            println!();
            continue;
        }
        println!(
            "  sessions: {}  ({} -> {}, {} scrapes, last scrape {})",
            r.session_count,
            fmt_ts(r.first_ts),
            fmt_ts(r.last_ts),
            r.scrape_count,
            r.last_status
        );
        println!("  prompt tokens (input):    {}", fmt_int(prompt));
        println!("  generation tokens (out):  {}", fmt_int(gen));
        println!("  requests:                 {}", fmt_int(reqs));
        println!("  cached prompt tokens:     {}", fmt_int(cached));
        match (r.hit_avg, r.hit_latest) {
            (Some(a), Some(l)) => println!(
                "  cache hit rate:           avg {:.1}%  latest {:.1}%",
                a * 100.0,
                l * 100.0
            ),
            _ => {}
        }
        println!(
            "  est. cloud API cost:      ${:.2}  (input ${:.2}/M, output ${:.2}/M)",
            r.est_cost, input_price, output_price
        );
        println!();
    }
    let tp: f64 = summaries
        .iter()
        .map(|r| r.grand.get(M_PROMPT).copied().unwrap_or(0.0))
        .sum();
    let tg: f64 = summaries
        .iter()
        .map(|r| r.grand.get(M_GEN).copied().unwrap_or(0.0))
        .sum();
    let tr: f64 = summaries
        .iter()
        .map(|r| r.grand.get(M_REQ).copied().unwrap_or(0.0))
        .sum();
    let tsv: f64 = tp / 1e6 * input_price + tg / 1e6 * output_price;
    println!("Totals across {} endpoint(s):", summaries.len());
    println!("  prompt tokens:   {}", fmt_int(tp));
    println!("  generation:      {}", fmt_int(tg));
    println!("  requests:        {}", fmt_int(tr));
    println!("  est. savings:    ${:.2}", tsv);
    0
}

fn json_report(summaries: &[EpSummary]) -> String {
    let mut s = String::from("[\n");
    for (i, r) in summaries.iter().enumerate() {
        if i > 0 {
            s.push_str(",\n");
        }
        s.push_str(&format!("  {{\n    \"endpoint\": \"{}\",\n", jesc(&r.endpoint)));
        s.push_str(&format!("    \"session_count\": {},\n", r.session_count));
        s.push_str(&format!(
            "    \"first_ts\": {},\n",
            r.first_ts
                .map(|t| format!("\"{}\"", iso_utc(t)))
                .unwrap_or_else(|| "null".into())
        ));
        s.push_str(&format!(
            "    \"last_ts\": {},\n",
            r.last_ts
                .map(|t| format!("\"{}\"", iso_utc(t)))
                .unwrap_or_else(|| "null".into())
        ));
        s.push_str(&format!("    \"scrape_count\": {},\n", r.scrape_count));
        s.push_str(&format!(
            "    \"last_status\": \"{}\",\n",
            jesc(&r.last_status)
        ));
        s.push_str(&format!(
            "    \"est_cost_usd\": {},\n",
            r.est_cost
        ));
        s.push_str("    \"sessions\": [\n");
        for (j, win) in r.sessions.iter().enumerate() {
            if j > 0 {
                s.push_str(",\n");
            }
            s.push_str("      {");
            s.push_str(&format!(
                "\"start\": {}, ",
                win.start
                    .map(|t| format!("\"{}\"", iso_utc(t)))
                    .unwrap_or_else(|| "null".into())
            ));
            s.push_str(&format!(
                "\"end\": {}",
                win.end
                    .map(|t| format!("\"{}\"", iso_utc(t)))
                    .unwrap_or_else(|| "null".into())
            ));
            s.push_str(",\n      \"totals\": {");
            let mut first = true;
            for (k, v) in &win.totals {
                if !first {
                    s.push(',');
                }
                first = false;
                s.push_str(&format!("\n        \"{}\": {}", jesc(k), v));
            }
            s.push_str("\n      }\n      }");
        }
        s.push_str("\n    ],\n    \"totals\": {");
        let mut first = true;
        for (k, v) in &r.grand {
            if !first {
                s.push(',');
            }
            first = false;
            s.push_str(&format!("\n      \"{}\": {}", jesc(k), v));
        }
        s.push_str("\n    },\n");
        s.push_str(&format!(
            "    \"cache_hit_rate\": {{\"avg\": {}, \"latest\": {}}}\n  }}",
            r.hit_avg.map(|v| v.to_string()).unwrap_or_else(|| "null".into()),
            r.hit_latest.map(|v| v.to_string()).unwrap_or_else(|| "null".into())
        ));
    }
    s.push_str("\n]\n");
    s
}

// ---------- main ----------

fn usage() {
    println!("sglang-usage: persist SGLang /metrics across sessions");
    println!("usage:");
    println!("  sglang-usage scrape --db PATH --endpoint HOST:PORT [--endpoint ...]");
    println!("      [--metrics a,b,c] [--timeout SECS]");
    println!("  sglang-usage report [--db PATH] [--input-price 3.0] [--output-price 15.0]");
    println!("      [--metrics a,b,c] [--json]");
    println!("  sglang-usage sessions [--db PATH]");
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.is_empty() {
        usage();
        std::process::exit(2);
    }
    let cmd = args[0].as_str();
    let rest: Vec<&str> = args[1..].iter().map(|s| s.as_str()).collect();
    let code = match cmd {
        "scrape" => cmd_scrape(&rest),
        "report" => run_report_and_sessions(&rest, false),
        "sessions" => run_report_and_sessions(&rest, true),
        "help" | "-h" | "--help" => {
            usage();
            0
        }
        _ => {
            eprintln!("unknown command: {cmd}");
            usage();
            2
        }
    };
    std::process::exit(code);
}
