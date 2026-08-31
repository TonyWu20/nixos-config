// sglang-usage: persist SGLang /metrics across sessions.
//
// `scrape` runs from a systemd timer. It pulls /metrics from each
// endpoint and appends TSV lines to a data file. The file grows
// across SGLang restarts, so usage accumulates forever. `report`
// and `sessions` aggregate the file: token totals, request counts,
// cached tokens, session counts, and the estimated cloud API cost
// that local serving saved.
//
// Single binary crate, built with cargo (see package.nix). The only
// external dependency is clap, used for argument parsing.

use std::collections::{BTreeMap, HashSet};
use std::fs::File;
use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::sync::OnceLock;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use clap::{Args, Parser, Subcommand, ValueEnum, ValueHint};

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

// ---------- CLI (clap) ----------

#[derive(Parser)]
#[command(
    name = "sglang-usage",
    version,
    about = "Persist SGLang /metrics across sessions.",
)]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Run one collection pass over the configured endpoints.
    Scrape(ScrapeArgs),
    /// Print the cumulative usage report.
    Report(ReportArgs),
    /// Print the per-session breakdown.
    Sessions(ReportArgs),
}

#[derive(Args)]
struct ScrapeArgs {
    /// Path of the append-only TSV data file.
    #[arg(long, default_value = DEFAULT_DB, value_hint = ValueHint::FilePath)]
    db: String,

    /// SGLang endpoint to scrape, HOST:PORT or NAME=HOST:PORT.
    /// Repeat the flag to cover several endpoints.
    #[arg(long, required = true)]
    endpoint: Vec<String>,

    /// Comma-separated metric names to persist.
    #[arg(long, value_delimiter = ',')]
    metrics: Option<Vec<String>>,

    /// Connect and read timeout in seconds.
    #[arg(long, default_value_t = 10.0)]
    timeout: f64,
}

#[derive(Args)]
struct ReportArgs {
    /// Path of the append-only TSV data file.
    #[arg(long, default_value = DEFAULT_DB, value_hint = ValueHint::FilePath)]
    db: String,

    /// Fallback input price, USD per million tokens.
    #[arg(long, default_value_t = 3.0)]
    input_price: f64,

    /// Fallback output price, USD per million tokens.
    #[arg(long, default_value_t = 15.0)]
    output_price: f64,

    /// JSON file with per-model prices.
    #[arg(long, value_hint = ValueHint::FilePath)]
    costs_file: Option<String>,

    /// Comma-separated metric names the report reads.
    #[arg(long, value_delimiter = ',')]
    metrics: Option<Vec<String>>,

    /// Output format for the report.
    #[arg(long, value_enum, default_value_t = Format::Text)]
    format: Format,

    /// Shorthand for --format json.
    #[arg(long)]
    json: bool,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq, ValueEnum)]
enum Format {
    Text,
    Json,
    Yaml,
    Toml,
}

struct Sample {
    name: String,
    labels: String,
    value: f64,
    kind: String,
}

fn default_metrics() -> Vec<String> {
    DEFAULT_METRICS.iter().map(|s| s.to_string()).collect()
}

// ---------- cost table (pi models.json) ----------

#[derive(Debug, Clone)]
enum Json {
    Null,
    Bool(bool),
    Num(f64),
    Str(String),
    Arr(Vec<Json>),
    Obj(Vec<(String, Json)>),
}

fn json_skip_ws(c: &[char], i: &mut usize) {
    while *i < c.len() {
        match c[*i] {
            ' ' | '\t' | '\n' | '\r' => *i += 1,
            _ => break,
        }
    }
}

fn json_parse_value(c: &[char], i: &mut usize) -> Result<Json, String> {
    json_skip_ws(c, i);
    let ch = c.get(*i).copied().ok_or("unexpected end of input")?;
    match ch {
        '{' => {
            *i += 1;
            let mut items: Vec<(String, Json)> = Vec::new();
            json_skip_ws(c, i);
            if c.get(*i) == Some(&'}') {
                *i += 1;
                return Ok(Json::Obj(items));
            }
            loop {
                json_skip_ws(c, i);
                let key = match json_parse_value(c, i)? {
                    Json::Str(s) => s,
                    _ => return Err("object key is not a string".to_string()),
                };
                json_skip_ws(c, i);
                if c.get(*i) != Some(&':') {
                    return Err("missing ':' in object".to_string());
                }
                *i += 1;
                let val = json_parse_value(c, i)?;
                items.push((key, val));
                json_skip_ws(c, i);
                match c.get(*i).copied() {
                    Some(',') => *i += 1,
                    Some('}') => {
                        *i += 1;
                        break;
                    }
                    _ => return Err("bad object syntax".to_string()),
                }
            }
            Ok(Json::Obj(items))
        }
        '[' => {
            *i += 1;
            let mut items: Vec<Json> = Vec::new();
            json_skip_ws(c, i);
            if c.get(*i) == Some(&']') {
                *i += 1;
                return Ok(Json::Arr(items));
            }
            loop {
                let val = json_parse_value(c, i)?;
                items.push(val);
                json_skip_ws(c, i);
                match c.get(*i).copied() {
                    Some(',') => *i += 1,
                    Some(']') => {
                        *i += 1;
                        break;
                    }
                    _ => return Err("bad array syntax".to_string()),
                }
            }
            Ok(Json::Arr(items))
        }
        '"' => {
            *i += 1;
            let mut out = String::new();
            loop {
                let ch = c.get(*i).copied().ok_or("unterminated string")?;
                *i += 1;
                match ch {
                    '"' => break,
                    '\\' => {
                        let esc = c.get(*i).copied().ok_or("bad escape")?;
                        *i += 1;
                        match esc {
                            '"' => out.push('"'),
                            '\\' => out.push('\\'),
                            '/' => out.push('/'),
                            'b' => out.push('\u{0008}'),
                            'f' => out.push('\u{000C}'),
                            'n' => out.push('\n'),
                            'r' => out.push('\r'),
                            't' => out.push('\t'),
                            'u' => {
                                let hex: u32 = c[*i..*i + 4]
                                    .iter()
                                    .collect::<String>()
                                    .parse()
                                    .map_err(|_| "bad \\u escape")?;
                                *i += 4;
                                let cp = if (0xD800..0xDC00).contains(&hex) {
                                    if c.get(*i) == Some(&'\\')
                                        && c.get(*i + 1) == Some(&'u')
                                    {
                                        let hex2: u32 = c[*i + 2..*i + 6]
                                            .iter()
                                            .collect::<String>()
                                            .parse()
                                            .map_err(|_| "bad surrogate".to_string())?;
                                        if (0xDC00..0xE000).contains(&hex2) {
                                            *i += 6;
                                            0x10000
                                                + ((hex - 0xD800) << 10)
                                                + (hex2 - 0xDC00)
                                        } else {
                                            0xFFFD
                                        }
                                    } else {
                                        0xFFFD
                                    }
                                } else {
                                    hex
                                };
                                out.push(char::from_u32(cp).unwrap_or('\u{FFFD}'));
                            }
                            _ => return Err("bad escape".to_string()),
                        }
                    }
                    _ => out.push(ch),
                }
            }
            Ok(Json::Str(out))
        }
        't' if c[*i..].starts_with(&['t', 'r', 'u', 'e']) => {
            *i += 4;
            Ok(Json::Bool(true))
        }
        'f' if c[*i..].starts_with(&['f', 'a', 'l', 's', 'e']) => {
            *i += 5;
            Ok(Json::Bool(false))
        }
        'n' if c[*i..].starts_with(&['n', 'u', 'l', 'l']) => {
            *i += 4;
            Ok(Json::Null)
        }
        _ => {
            let start = *i;
            while *i < c.len()
                && matches!(c[*i], '-' | '+' | '.' | 'e' | 'E' | '0'..='9')
            {
                *i += 1;
            }
            let s: String = c[start..*i].iter().collect();
            if s.is_empty() {
                return Err("unexpected character".to_string());
            }
            s.parse::<f64>().map(Json::Num).map_err(|_| "bad number".to_string())
        }
    }
}

fn json_obj_get<'a>(o: &'a [ (String, Json) ], key: &str) -> Option<&'a Json> {
    o.iter().find(|(k, _)| k == key).map(|(_, v)| v)
}

fn parse_json(text: &str) -> Result<Json, String> {
    let c: Vec<char> = text.chars().collect();
    let mut i = 0;
    let v = json_parse_value(&c, &mut i)?;
    Ok(v)
}

struct PriceEntry {
    ids: Vec<String>,
    input: f64,
    output: f64,
    cache_read: f64,
}

// Generic costs file schema (no tool or harness knowledge):
//
//   {
//     "models": { "<name>": { "input": 0.44, "output": 1.32,
//                              "cacheRead": 0.014 }, ... },
//     "default": { "input": 1.74, "output": 3.48, "cacheRead": 0.145 }
//   }

// Prices are USD per million tokens. Missing fields read as 0.0.
fn load_price_table(path: &str) -> Result<Vec<PriceEntry>, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("{path}: {e}"))?;
    let root = parse_json(&text).map_err(|e| format!("{path}: {e}"))?;
    let items = match &root {
        Json::Obj(o) => o,
        _ => return Err(format!("{path}: root is not an object")),
    };
    let num = |o: &[(String, Json)], k: &str| match json_obj_get(o, k) {
        Some(Json::Num(n)) => *n,
        _ => 0.0,
    };
    let entry_from_obj = |e: &[(String, Json)], id: String| -> PriceEntry {
        let mut ids = vec![id];
        if let Some(Json::Str(name)) = json_obj_get(e, "name") {
            ids.push(name.clone());
        }
        PriceEntry {
            ids,
            input: num(e, "input"),
            output: num(e, "output"),
            cache_read: num(e, "cacheRead"),
        }
    };
    let mut out: Vec<PriceEntry> = Vec::new();
    if let Some(m) = json_obj_get(items, "models") {
        match m {
            Json::Obj(models) => {
                // map form: { "models": { "<id>": { ... } } }
                for (name, entry) in models {
                    if let Json::Obj(e) = entry {
                        out.push(entry_from_obj(e, name.clone()));
                    }
                }
            }
            Json::Arr(arr) => {
                // list form: { "models": [ { "id": ..., ... } ] }
                for el in arr {
                    if let Json::Obj(e) = el {
                        if let Some(Json::Str(id)) = json_obj_get(e, "id") {
                            out.push(entry_from_obj(e, id.clone()));
                        }
                    }
                }
            }
            _ => {}
        }
    }
    if let Some(Json::Obj(e)) = json_obj_get(items, "default") {
        out.push(PriceEntry {
            ids: vec!["default".to_string()],
            input: num(e, "input"),
            output: num(e, "output"),
            cache_read: num(e, "cacheRead"),
        });
    }
    if out.is_empty() {
        return Err(format!("{path}: no model entries found"));
    }
    Ok(out)
}

fn default_entry(table: &[PriceEntry]) -> Option<&PriceEntry> {
    table.iter().find(|e| e.ids.iter().any(|i| i == "default"))
}

fn norm_model(s: &str) -> String {
    s.trim().trim_end_matches('/').to_string()
}

// A label and an id match when one is a full prefix of the other at a
// '-' boundary. Longer overlap wins; ties go to the longer id.
fn overlap_score(label: &str, cand: &str) -> usize {
    let l = norm_model(label);
    let c = norm_model(cand);
    if l == c {
        return 1 << 30;
    }
    if l.starts_with(&c) {
        if c.is_empty() || l.as_bytes().get(c.len()) == Some(&b'-') {
            return c.len();
        }
        return 0;
    }
    if c.starts_with(&l) {
        if l.is_empty() || c.as_bytes().get(l.len()) == Some(&b'-') {
            return l.len();
        }
    }
    0
}

fn match_price<'a>(table: &'a [PriceEntry], label: &str) -> Option<&'a PriceEntry> {
    let mut best: Option<(usize, usize, &PriceEntry)> = None;
    for e in table {
        let score = e
            .ids
            .iter()
            .map(|id| overlap_score(label, id))
            .max()
            .unwrap_or(0);
        if score == 0 {
            continue;
        }
        let spec = e.ids.iter().map(|id| id.len()).max().unwrap_or(0);
        match best {
            Some((bs, bspec, _)) => {
                if score > bs || (score == bs && spec > bspec) {
                    best = Some((score, spec, e));
                }
            }
            None => best = Some((score, spec, e)),
        }
    }
    best.map(|(_, _, e)| e)
}

fn extract_model(labels: &str) -> String {
    if let Some(p) = labels.find("model_name=\"") {
        let rest = &labels[p + "model_name=\"".len()..];
        let v = rest.split('"').next().unwrap_or("");
        if !v.is_empty() {
            return v.to_string();
        }
    }
    "unknown".to_string()
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
    let mut buf: Vec<u8> = Vec::new();
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

struct ModelCost {
    model: String,
    prompt: f64,
    cached: f64,
    gen: f64,
    reqs: f64,
    matched: Option<String>,
    input_price: f64,
    output_price: f64,
    cache_read_price: f64,
    est_cost: f64,
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
    model_costs: Vec<ModelCost>,
    est_cost: f64,
    costs_file: Option<String>,
}

fn endpoint_summary(
    ep: &str,
    rows: &[(f64, String, String, f64, String)],
    wanted: &[String],
    meta: Option<&(f64, f64, u64, String)>,
    price_table: Option<&[PriceEntry]>,
    fb_in: f64,
    fb_out: f64,
    costs_file: Option<String>,
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
            model_costs: Vec::new(),
            est_cost: 0.0,
            costs_file,
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
    // Per-model totals: prompt, cached, generation, requests.
    let mut model_grand: BTreeMap<String, (f64, f64, f64, f64)> = BTreeMap::new();
    for (ws, we) in &windows {
        let mut tot: BTreeMap<String, f64> = BTreeMap::new();
        let mut model_tot: BTreeMap<String, (f64, f64, f64, f64)> = BTreeMap::new();
        for ((name, labels), (ts, vals, _)) in &series {
            if !wanted.iter().any(|m| m == name) {
                continue;
            }
            let mut last: Option<f64> = None;
            for i in 0..ts.len() {
                if ts[i] >= ws.unwrap_or(f64::MIN) && (we.is_none() || ts[i] < we.unwrap()) {
                    last = Some(vals[i]);
                }
            }
            let v = match last {
                Some(v) => v,
                None => continue,
            };
            *tot.entry(name.clone()).or_insert(0.0) += v;
            match name.as_str() {
                M_PROMPT | M_CACHED | M_GEN | M_REQ => {
                    let model = extract_model(labels);
                    let e = model_tot.entry(model).or_insert((0.0, 0.0, 0.0, 0.0));
                    match name.as_str() {
                        M_PROMPT => e.0 += v,
                        M_CACHED => e.1 += v,
                        M_GEN => e.2 += v,
                        M_REQ => e.3 += v,
                        _ => {}
                    }
                }
                _ => {}
            }
        }
        for (k, v) in &tot {
            *grand.entry(k.clone()).or_insert(0.0) += v;
        }
        for (m, t) in &model_tot {
            let e = model_grand.entry(m.clone()).or_insert((0.0, 0.0, 0.0, 0.0));
            e.0 += t.0;
            e.1 += t.1;
            e.2 += t.2;
            e.3 += t.3;
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
    let cached = grand.get(M_CACHED).copied().unwrap_or(0.0);

    // Per-model cost estimate. Cached prompt tokens bill at the
    // cacheRead price. Cached counts can exceed the prompt total due
    // to chunked-prefill re-counts, so clamp to the prompt total.
    let mut model_costs: Vec<ModelCost> = Vec::new();
    let mut est_cost = 0.0;
    for (model, (p, c, g, rq)) in &model_grand {
        let (p, c, g, rq) = (*p, *c, *g, *rq);
        let matched = price_table
            .and_then(|t| match_price(t, model))
            .or_else(|| price_table.and_then(|t| default_entry(t)));
        let (in_p, out_p, cr_p, mid) = match matched {
            Some(e) => (e.input, e.output, e.cache_read, Some(e.ids[0].clone())),
            None => (fb_in, fb_out, 0.0, None),
        };
        let cr = if cr_p > 0.0 { cr_p } else { in_p };
        let uncached = (p - c).max(0.0);
        let cached_billed = c.min(p);
        let cost = uncached / 1e6 * in_p + cached_billed / 1e6 * cr + g / 1e6 * out_p;
        est_cost += cost;
        model_costs.push(ModelCost {
            model: model.clone(),
            prompt: p,
            cached: c,
            gen: g,
            reqs: rq,
            matched: mid,
            input_price: in_p,
            output_price: out_p,
            cache_read_price: cr_p,
            est_cost: cost,
        });
    }
    if model_costs.is_empty() {
        est_cost = (prompt - cached).max(0.0) / 1e6 * fb_in + cached.min(prompt) / 1e6 * fb_in + gen / 1e6 * fb_out;
    }

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
        model_costs,
        est_cost,
        costs_file,
    }
}

// ---------- local time ----------

// glibc struct tm layout on x86_64 Linux. The last two fields
// (tm_gmtoff, tm_zone) extend the POSIX base and are stable in glibc.
#[repr(C)]
struct Tm {
    tm_sec: i32,
    tm_min: i32,
    tm_hour: i32,
    tm_mday: i32,
    tm_mon: i32,
    tm_year: i32,
    tm_wday: i32,
    tm_yday: i32,
    tm_isdst: i32,
    tm_gmtoff: i64,
    tm_zone: *const i8,
}

extern "C" {
    fn localtime_r(timep: *const i64, result: *mut Tm) -> *mut Tm;
}

struct TzInfo {
    zone: String,
    offset: i64,
}

// Current local zone name and UTC offset, read once.
fn tz_info() -> &'static TzInfo {
    static ONCE: OnceLock<TzInfo> = OnceLock::new();
    ONCE.get_or_init(|| {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs() as i64)
            .unwrap_or(0);
        let mut tm: Tm = unsafe { std::mem::zeroed() };
        if unsafe { localtime_r(&now, &mut tm) }.is_null() {
            return TzInfo {
                zone: "UTC".to_string(),
                offset: 0,
            };
        }
        TzInfo {
            zone: zone_name(&tm),
            offset: tm.tm_gmtoff,
        }
    })
}

fn zone_name(tm: &Tm) -> String {
    let s = unsafe { std::ffi::CStr::from_ptr(tm.tm_zone) }
        .to_string_lossy()
        .into_owned();
    if s.trim().is_empty() {
        "UTC".to_string()
    } else {
        s
    }
}

// Local calendar parts for the moment `ts` (epoch seconds):
// (year, month, day, hour, minute, UTC offset, zone name). The offset
// and zone honor DST rules for that exact moment.
fn local_parts(ts: f64) -> (i64, u32, u32, u32, u32, i64, String) {
    let t = ts as i64;
    let mut tm: Tm = unsafe { std::mem::zeroed() };
    if unsafe { localtime_r(&t, &mut tm) }.is_null() {
        // No tz database; fall back to UTC civil days.
        let days = t.div_euclid(86400);
        let rem = t.rem_euclid(86400);
        let (y, mo, d) = civil_from_days(days);
        return (
            y,
            mo,
            d,
            (rem / 3600) as u32,
            ((rem % 3600) / 60) as u32,
            0,
            "UTC".to_string(),
        );
    }
    (
        tm.tm_year as i64 + 1900,
        tm.tm_mon as u32 + 1,
        tm.tm_mday as u32,
        tm.tm_hour as u32,
        tm.tm_min as u32,
        tm.tm_gmtoff,
        zone_name(&tm),
    )
}

// "2025-11-16 09:41 CST"
fn fmt_local(ts: f64) -> String {
    let (y, mo, d, h, mi, _off, zone) = local_parts(ts);
    format!("{:04}-{:02}-{:02} {:02}:{:02} {zone}", y, mo, d, h, mi)
}

// "2025-11-16T09:41-06:00"
fn iso_local(ts: f64) -> String {
    let (y, mo, d, h, mi, off, _zone) = local_parts(ts);
    let (sign, abs) = if off < 0 {
        ("-", -off)
    } else {
        ("+", off)
    };
    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}{sign}{:02}:{:02}",
        y,
        mo,
        d,
        h,
        mi,
        abs / 3600,
        (abs % 3600) / 60
    )
}

fn fmt_ts(ts: Option<f64>) -> String {
    match ts {
        Some(v) => fmt_local(v),
        None => "ongoing".to_string(),
    }
}

fn civil_from_days(z0: i64) -> (i64, u32, u32) {
    // Howard Hinnant's civil calendar algorithm. Used only as a UTC
    // fallback when localtime_r fails.
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

fn cmd_scrape(args: &ScrapeArgs) -> i32 {
    let db = args.db.clone();
    let timeout_s = args.timeout;
    let metrics = args.metrics.clone().unwrap_or_else(default_metrics);
    let wanted: HashSet<String> = metrics.iter().cloned().collect();
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0);
    let mut file = match File::options().create(true).append(true).open(&db) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("scrape: cannot open {db}: {e}");
            return 1;
        }
    };
    let mut ok_count = 0usize;
    for ep in &args.endpoint {
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

fn run_report_and_sessions(args: &ReportArgs, sessions_only: bool) -> i32 {
    let db = args.db.clone();
    let input_price = args.input_price;
    let output_price = args.output_price;
    let format = if args.json { Format::Json } else { args.format };
    let costs_file = args.costs_file.clone();
    let mut table: Option<Vec<PriceEntry>> = None;
    if let Some(path) = &costs_file {
        match load_price_table(path) {
            Ok(t) => table = Some(t),
            Err(e) => eprintln!("report: {e} (using fallback prices)"),
        }
    }
    let metrics: Vec<String> = args.metrics.clone().unwrap_or_else(default_metrics);
    let (rows, meta) = match load_db(&db) {
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
        summaries.push(endpoint_summary(
            ep,
            r,
            &metrics,
            meta.get(ep),
            table.as_deref(),
            input_price,
            output_price,
            costs_file.clone(),
        ));
    }
    if format != Format::Text {
        match format {
            Format::Text => unreachable!(),
            Format::Json => print!("{}", json_report(&summaries)),
            Format::Yaml => print!("{}", yaml_report(&summaries)),
            Format::Toml => print!("{}", toml_report(&summaries)),
        }
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
                    Some(v) => format!("{} ", fmt_local(v)),
                    None => "db start  ".to_string(),
                };
                let end = match s.end {
                    Some(v) => fmt_local(v),
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
        if !r.model_costs.is_empty() {
            println!("  by model:");
            for m in &r.model_costs {
                let mname = m
                    .matched
                    .as_deref()
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| "default price".to_string());
                println!("    {}  [{} in costs file]", m.model, mname);
                println!(
                    "      prompt={} cached={} gen={} reqs={}",
                    fmt_int(m.prompt),
                    fmt_int(m.cached),
                    fmt_int(m.gen),
                    fmt_int(m.reqs)
                );
                println!(
                    "      prices: in ${:.3}/M  out ${:.3}/M  cache ${:.3}/M",
                    m.input_price, m.output_price, m.cache_read_price
                );
                println!("      est. cost: ${:.2}", m.est_cost);
            }
        }
        println!("  est. cloud API cost:      ${:.2}", r.est_cost);
        match &r.costs_file {
            Some(p) => println!("  prices from: {p}"),
            None => println!(
                "  prices: fallback (input ${:.2}/M, output ${:.2}/M); use --costs-file for per-model prices",
                input_price, output_price
            ),
        }
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
    let tcost: f64 = summaries.iter().map(|r| r.est_cost).sum();
    println!("Totals across {} endpoint(s):", summaries.len());
    println!("  prompt tokens:   {}", fmt_int(tp));
    println!("  generation:      {}", fmt_int(tg));
    println!("  requests:        {}", fmt_int(tr));
    println!("  est. savings:    ${:.2}", tcost);
    0
}

// ---------- structured output ----------

fn num_or_null(v: Option<f64>) -> String {
    match v {
        Some(x) => x.to_string(),
        None => "null".to_string(),
    }
}

fn str_or_null(v: Option<String>) -> String {
    match v {
        Some(x) => format!("\"{}\"", jesc(&x)),
        None => "null".to_string(),
    }
}

fn json_report(summaries: &[EpSummary]) -> String {
    let tz = tz_info();
    let mut s = String::from("[\n");
    for (i, r) in summaries.iter().enumerate() {
        if i > 0 {
            s.push_str(",\n");
        }
        s.push_str(&format!("  {{\n    \"endpoint\": \"{}\",\n", jesc(&r.endpoint)));
        s.push_str(&format!(
            "    \"timezone\": \"{}\",\n",
            jesc(&tz.zone)
        ));
        s.push_str(&format!(
            "    \"timezone_offset_seconds\": {},\n",
            tz.offset
        ));
        s.push_str(&format!(
            "    \"session_count\": {},\n",
            r.session_count
        ));
        s.push_str(&format!("    \"first_ts\": {},\n", num_or_null(r.first_ts)));
        s.push_str(&format!(
            "    \"first_ts_local\": {},\n",
            str_or_null(r.first_ts.map(iso_local))
        ));
        s.push_str(&format!("    \"last_ts\": {},\n", num_or_null(r.last_ts)));
        s.push_str(&format!(
            "    \"last_ts_local\": {},\n",
            str_or_null(r.last_ts.map(iso_local))
        ));
        s.push_str(&format!(
            "    \"scrape_count\": {},\n",
            r.scrape_count
        ));
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
                num_or_null(win.start)
            ));
            s.push_str(&format!(
                "\"end\": {}, ",
                num_or_null(win.end)
            ));
            s.push_str(&format!(
                "\"start_local\": {}, ",
                str_or_null(win.start.map(iso_local))
            ));
            s.push_str(&format!(
                "\"end_local\": {}",
                str_or_null(win.end.map(iso_local))
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
            "    \"cache_hit_rate\": {{\"avg\": {}, \"latest\": {}}},\n",
            r.hit_avg.map(|v| v.to_string()).unwrap_or_else(|| "null".into()),
            r.hit_latest.map(|v| v.to_string()).unwrap_or_else(|| "null".into())
        ));
        s.push_str("    \"by_model\": [\n");
        for (j, m) in r.model_costs.iter().enumerate() {
            if j > 0 {
                s.push_str(",\n");
            }
            s.push_str("      {");
            s.push_str(&format!(
                "\"model\": \"{}\", ",
                jesc(&m.model)
            ));
            s.push_str(&format!(
                "\"matched\": {}, ",
                m.matched
                    .as_ref()
                    .map(|x| format!("\"{}\"", jesc(x)))
                    .unwrap_or_else(|| "null".into())
            ));
            s.push_str(&format!(
                "\"prompt_tokens\": {}, \"cached_tokens\": {}, ",
                m.prompt, m.cached
            ));
            s.push_str(&format!(
                "\"generation_tokens\": {}, \"requests\": {}, ",
                m.gen, m.reqs
            ));
            s.push_str(&format!(
                "\"input_price\": {}, \"output_price\": {}, \"cache_read_price\": {}, ",
                m.input_price, m.output_price, m.cache_read_price
            ));
            s.push_str(&format!("\"est_cost_usd\": {}", m.est_cost));
            s.push_str("}");
        }
        s.push_str("\n    ],\n");
        s.push_str(&format!(
            "    \"costs_file\": {}\n  }}",
            r.costs_file
                .as_ref()
                .map(|x| format!("\"{}\"", jesc(x)))
                .unwrap_or_else(|| "null".into())
        ));
    }
    s.push_str("\n]\n");
    s
}

fn y_s(v: &str) -> String {
    format!("\"{}\"", jesc(v))
}

fn y_s_opt(v: Option<String>) -> String {
    match v {
        Some(x) => y_s(&x),
        None => "null".to_string(),
    }
}

fn yaml_report(summaries: &[EpSummary]) -> String {
    let mut s = String::new();
    for (i, r) in summaries.iter().enumerate() {
        if i > 0 {
            s.push('\n');
        }
        s.push_str(&yaml_endpoint(r));
    }
    s.push('\n');
    s
}

fn yaml_endpoint(r: &EpSummary) -> String {
    let tz = tz_info();
    let i = "  ";
    let j = "    ";
    let k = "      ";
    let mut s = String::new();
    s.push_str(&format!("- endpoint: {}\n", y_s(&r.endpoint)));
    s.push_str(&format!("{i}timezone: {}\n", y_s(&tz.zone)));
    s.push_str(&format!(
        "{i}timezone_offset_seconds: {}\n",
        tz.offset
    ));
    s.push_str(&format!("{i}session_count: {}\n", r.session_count));
    s.push_str(&format!("{i}first_ts: {}\n", num_or_null(r.first_ts)));
    s.push_str(&format!(
        "{i}first_ts_local: {}\n",
        y_s_opt(r.first_ts.map(iso_local))
    ));
    s.push_str(&format!("{i}last_ts: {}\n", num_or_null(r.last_ts)));
    s.push_str(&format!(
        "{i}last_ts_local: {}\n",
        y_s_opt(r.last_ts.map(iso_local))
    ));
    s.push_str(&format!("{i}scrape_count: {}\n", r.scrape_count));
    s.push_str(&format!("{i}last_status: {}\n", y_s(&r.last_status)));
    s.push_str(&format!("{i}est_cost_usd: {}\n", r.est_cost));
    s.push_str(&format!(
        "{i}costs_file: {}\n",
        y_s_opt(r.costs_file.clone())
    ));
    s.push('\n');
    if r.sessions.is_empty() {
        s.push_str(&format!("{i}sessions: []\n"));
    } else {
        s.push_str(&format!("{i}sessions:\n"));
        for win in &r.sessions {
            s.push_str(&format!("{j}- start: {}\n", num_or_null(win.start)));
            s.push_str(&format!("{j}  end: {}\n", num_or_null(win.end)));
            s.push_str(&format!(
                "{j}  start_local: {}\n",
                y_s_opt(win.start.map(iso_local))
            ));
            s.push_str(&format!(
                "{j}  end_local: {}\n",
                y_s_opt(win.end.map(iso_local))
            ));
            s.push_str(&format!("{j}  totals:\n"));
            for (key, v) in &win.totals {
                s.push_str(&format!("{k}{}: {}\n", y_s(key), v));
            }
        }
    }
    s.push('\n');
    if r.grand.is_empty() {
        s.push_str(&format!("{i}totals: {{}}\n"));
    } else {
        s.push_str(&format!("{i}totals:\n"));
        for (key, v) in &r.grand {
            s.push_str(&format!("{j}{}: {}\n", y_s(key), v));
        }
    }
    s.push('\n');
    s.push_str(&format!("{i}cache_hit_rate:\n"));
    s.push_str(&format!("{j}avg: {}\n", num_or_null(r.hit_avg)));
    s.push_str(&format!("{j}latest: {}\n", num_or_null(r.hit_latest)));
    s.push('\n');
    if r.model_costs.is_empty() {
        s.push_str(&format!("{i}by_model: []\n"));
    } else {
        s.push_str(&format!("{i}by_model:\n"));
        for mc in &r.model_costs {
            s.push_str(&format!("{j}- model: {}\n", y_s(&mc.model)));
            s.push_str(&format!(
                "{j}  matched: {}\n",
                y_s_opt(mc.matched.clone())
            ));
            s.push_str(&format!("{j}  prompt_tokens: {}\n", mc.prompt));
            s.push_str(&format!("{j}  cached_tokens: {}\n", mc.cached));
            s.push_str(&format!("{j}  generation_tokens: {}\n", mc.gen));
            s.push_str(&format!("{j}  requests: {}\n", mc.reqs));
            s.push_str(&format!("{j}  input_price: {}\n", mc.input_price));
            s.push_str(&format!("{j}  output_price: {}\n", mc.output_price));
            s.push_str(&format!(
                "{j}  cache_read_price: {}\n",
                mc.cache_read_price
            ));
            s.push_str(&format!("{j}  est_cost_usd: {}\n", mc.est_cost));
        }
    }
    s
}

fn t_s(v: &str) -> String {
    format!("\"{}\"", jesc(v))
}

fn t_f(v: f64) -> String {
    if !v.is_finite() {
        return "0.0".to_string();
    }
    let t = v.to_string();
    if t.contains('.') || t.contains('e') {
        t
    } else {
        format!("{t}.0")
    }
}

fn t_f_opt(out: &mut String, key: &str, v: Option<f64>) {
    if let Some(x) = v {
        out.push_str(&format!("{key} = {}\n", t_f(x)));
    }
}

fn t_s_opt(out: &mut String, key: &str, v: Option<String>) {
    if let Some(x) = v {
        out.push_str(&format!("{key} = {}\n", t_s(&x)));
    }
}

fn toml_report(summaries: &[EpSummary]) -> String {
    let tz = tz_info();
    let mut s = String::new();
    s.push_str("# sglang-usage report\n");
    s.push_str(&format!("timezone = {}\n", t_s(&tz.zone)));
    s.push_str(&format!(
        "timezone_offset_seconds = {}\n\n",
        tz.offset
    ));
    for r in summaries {
        s.push_str(&toml_endpoint(r));
    }
    s
}

fn toml_endpoint(r: &EpSummary) -> String {
    let mut s = String::new();
    s.push_str("[[endpoints]]\n");
    s.push_str(&format!("endpoint = {}\n", t_s(&r.endpoint)));
    s.push_str(&format!("session_count = {}\n", r.session_count));
    t_f_opt(&mut s, "first_ts", r.first_ts);
    t_s_opt(&mut s, "first_ts_local", r.first_ts.map(iso_local));
    t_f_opt(&mut s, "last_ts", r.last_ts);
    t_s_opt(&mut s, "last_ts_local", r.last_ts.map(iso_local));
    s.push_str(&format!("scrape_count = {}\n", r.scrape_count));
    s.push_str(&format!(
        "last_status = {}\n",
        t_s(&r.last_status)
    ));
    s.push_str(&format!("est_cost_usd = {}\n", t_f(r.est_cost)));
    t_s_opt(&mut s, "costs_file", r.costs_file.clone());

    if r.sessions.is_empty() {
        s.push_str("sessions = []\n");
    } else {
        for win in &r.sessions {
            s.push_str("[[endpoints.sessions]]\n");
            t_f_opt(&mut s, "start", win.start);
            t_f_opt(&mut s, "end", win.end);
            t_s_opt(&mut s, "start_local", win.start.map(iso_local));
            t_s_opt(&mut s, "end_local", win.end.map(iso_local));
            s.push_str("[endpoints.sessions.totals]\n");
            for (key, v) in &win.totals {
                s.push_str(&format!("{} = {}\n", t_s(key), t_f(*v)));
            }
        }
        s.push('\n');
    }

    if r.model_costs.is_empty() {
        s.push_str("by_model = []\n");
    } else {
        for mc in &r.model_costs {
            s.push_str("[[endpoints.by_model]]\n");
            s.push_str(&format!("model = {}\n", t_s(&mc.model)));
            t_s_opt(&mut s, "matched", mc.matched.clone());
            s.push_str(&format!("prompt_tokens = {}\n", t_f(mc.prompt)));
            s.push_str(&format!("cached_tokens = {}\n", t_f(mc.cached)));
            s.push_str(&format!(
                "generation_tokens = {}\n",
                t_f(mc.gen)
            ));
            s.push_str(&format!("requests = {}\n", t_f(mc.reqs)));
            s.push_str(&format!("input_price = {}\n", t_f(mc.input_price)));
            s.push_str(&format!("output_price = {}\n", t_f(mc.output_price)));
            s.push_str(&format!(
                "cache_read_price = {}\n",
                t_f(mc.cache_read_price)
            ));
            s.push_str(&format!("est_cost_usd = {}\n", t_f(mc.est_cost)));
        }
        s.push('\n');
    }

    if r.grand.is_empty() {
        s.push_str("totals = {}\n");
    } else {
        s.push_str("[endpoints.totals]\n");
        for (key, v) in &r.grand {
            s.push_str(&format!("{} = {}\n", t_s(key), t_f(*v)));
        }
    }

    if r.hit_avg.is_some() || r.hit_latest.is_some() {
        s.push_str("[endpoints.cache_hit_rate]\n");
        t_f_opt(&mut s, "avg", r.hit_avg);
        t_f_opt(&mut s, "latest", r.hit_latest);
    }
    s.push('\n');
    s
}

// ---------- main ----------

fn main() {
    let cli = Cli::parse();
    let code = match cli.cmd {
        Cmd::Scrape(a) => cmd_scrape(&a),
        Cmd::Report(a) => run_report_and_sessions(&a, false),
        Cmd::Sessions(a) => run_report_and_sessions(&a, true),
    };
    std::process::exit(code);
}
