# sglang-metrics

Persists SGLang `/metrics` across sessions. A systemd timer scrapes
each configured endpoint every 5 minutes and appends the usage
counters to an append-only TSV file at `/var/lib/sglang-metrics/usage.tsv`.
The file survives SGLang restarts. SGLang counters reset on every
restart, so the tool detects each reset as a session boundary and
aggregates sessions into lifetime totals.

The SGLang server config must set `enable-metrics: true`.

## Commands

- `sglang-usage report` — cumulative totals, sessions, cache hit
  rate, per-model costs, the current running and queued request
  counts (`sglang:num_running_reqs` and `sglang:num_queue_reqs`,
  latest scrape values with their local times), and the estimated
  cloud API cost this local serving saved. The wrapper uses the
  prices set in the Nix module.

- `sglang-usage sessions` — per-session breakdown (start, end,
  prompt tokens, generation tokens, requests, cached tokens).

- `sglang-usage scrape --db PATH --endpoint HOST:PORT` — run one
  collection pass by hand (`sudo systemctl start
  sglang-metrics-collect` works too).

- `sglang-usage report --format json|yaml|toml` — structured output.
  `--json` stays as a shortcut for `--format json`.

## Report flags

- `--format text|json|yaml|toml` — output format. The text format is
  the default. Structured formats carry one entry per endpoint:
  totals, sessions, per-model costs, cache hit rate, running and
  queued requests (`running_requests` and `queued_requests`, each
  with `latest`, `latest_ts`, and `latest_ts_local`), and the
  estimated cloud cost. Timestamps are epoch seconds (`*_ts`) plus a
  local time string (`*_ts_local`, e.g. `2025-11-15T06:13+08:00`).
  TOML omits fields that are null.

- `--costs-file PATH` — JSON file with per-model prices (see below).
  The Nix wrapper passes the `costsFile` option automatically.

- `--input-price N` / `--output-price N` — USD per million tokens.
  Defaults are 3.0 / 15.0. Used for models that the costs file does
  not match.

- `--metrics a,b,c` — change which metric names the report reads.

## Time display

Report times show in the local timezone (the `TZ` of the machine
that runs the report, DST rules included). Structured output adds
`timezone` (zone abbreviation, e.g. `HKT`) and
`timezone_offset_seconds` for the current local zone.

## Build

Single binary crate, built with cargo. Dependencies are pinned in
`Cargo.lock` (fetched from crates.io at build time, then the build
runs offline). The only dependency is clap, used for argument
parsing. `package.nix` builds the tool via
`rustPlatform.buildRustPackage`.

## Costs file

The tool reads a JSON file with its own schema. It has no link to
any harness or provider config. Two forms of `models` work: 

```
{
  "models": [
    { "id": "<model id>", "input": 0.44, "output": 1.32, "cacheRead": 0.014 }
  ],
  "default": { "input": 3.0, "output": 15.0, "cacheRead": 0.3 }
}
```

or `"models": { "<id>": { "input": ..., ... } }` as a map. Prices
are USD per 1M tokens. `cacheRead` is optional. A missing `cacheRead`
bills cached tokens at the input price. `default` applies to models
the `models` list does not match.

The Nix module writes this file from the `costs` option. If you keep
the file outside Nix, point `costsFile` at it and keep the `costs`
option only for the fallback prices.

Matching: the `model_name` label SGLang reports (trailing `/`
removed) is compared against each entry `id` (and `name` if present).
The match is a prefix at a `-` boundary. The longest overlap wins.

## Nix options

Set them in `nixos-pro5000/configuration.nix`:

```
services.sglangMetrics = {
  enable = true;
  endpoints = [ "127.0.0.1:30000" ];
  intervalMins = 5;
  # Per-model prices, USD per 1M tokens. The module writes this table
  # to /etc/sglang-metrics/costs.json at activation.
  costs = {
    models = [
      { id = "Qwen3.8-27B-NVFP4-RTX5090-DSPARK"; input = 0.44; output = 1.32; cacheRead = 0.014; }
    ];
    default = { input = 3.0; output = 15.0; cacheRead = 0.3; };
  };
};
```

`costsFile` points the report at the costs table. Default is the
file the module writes from `costs`.

`costs.default` prices models that no `costs.models` entry matches.
It also feeds the `--input-price`/`--output-price` fallback of the
report wrapper.

## Data format

TSV, two line types:

```
S  <ts>  <endpoint>  ok|down  <detail>
X  <ts>  <endpoint>  <metric>  <labels>  <value>  <kind>
```

`ts` is epoch seconds. `kind` is `counter` or `gauge`. Counters that
drop below the last stored value mark a session boundary.

## Install

On nixos-pro5000, activate the system after a config change:

```
sudo nixos-rebuild switch --flake ~/nixos-config#nixos-pro5000
```

The timer `sglang-metrics-collect.timer` then collects once per
minute after boot, then every `intervalMins`. Run one pass by hand
with `sudo systemctl start sglang-metrics-collect.service`.
Data lands in `/var/lib/sglang-metrics/usage.tsv`.

## Cost estimate

Per model, the report computes:

```
cost = uncached_prompt/1e6 * input
     + cached_prompt/1e6 * cacheRead
     + generation/1e6 * output
```

`uncached_prompt` is `prompt_tokens - cached_tokens`, clamped at 0.
`cached_prompt` is clamped at the prompt total, because chunked
prefill can count some tokens in both counters. The per-model costs
sum to the "est. cloud API cost" line.

It is a rough guide. Set the `costs` option to the real prices of the
cloud API you replace. Tokens processed while the timer was not
running (at most one interval) are not counted.
