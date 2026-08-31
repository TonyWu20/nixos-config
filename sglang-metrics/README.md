# sglang-metrics

Persists SGLang `/metrics` across sessions. A systemd timer scrapes
each configured endpoint every 5 minutes and appends the usage
counters to an append-only TSV file at `/var/lib/sglang-metrics/usage.tsv`.
The file survives SGLang restarts. SGLang counters reset on every
restart, so the tool detects each reset as a session boundary and
aggregates sessions into lifetime totals.

Requires `enable-metrics: true` in the SGLang server config.

## Commands

- `sglang-usage report` — cumulative totals, sessions, cache hit
  rate, per-model costs, and the estimated cloud API cost this local
  serving saved. The wrapper uses the prices set in the Nix module.

- `sglang-usage sessions` — per-session breakdown (start, end,
  prompt tokens, generation tokens, requests, cached tokens).

- `sglang-usage scrape --db PATH --endpoint HOST:PORT` — run one
  collection pass by hand (`sudo systemctl start
  sglang-metrics-collect` works too).

- `sglang-usage report --json` — machine-readable output.

## Report flags

- `--costs-file PATH` — JSON file with per-model prices (see below).
  The Nix wrapper passes the `costsFile` option automatically.

- `--input-price N` / `--output-price N` — USD per million tokens.
  Defaults are 3.0 / 15.0. Used for models that the costs file does
  not match.

- `--metrics a,b,c` — change which metric names the report reads.

## Costs file

The file has its own schema. No harness or provider config: 

```
{
  "models": {
    "<model-id or name>": { "input": 0.44, "output": 1.32, "cacheRead": 0.014 }
  },
  "default": { "input": 3.0, "output": 15.0, "cacheRead": 0.3 }
}
```

Prices are USD per 1M tokens. `cacheRead` is optional. A missing
`cacheRead` bills cached tokens at the input price. `default` applies
to models the `models` map does not match.

Matching: the label of the model SGLang reports (`model_name` label,
trailing `/` removed) is compared against each entry. The match is a
prefix at a `-` boundary. The longest overlap wins.

The default costs file is `~/.local/share/sglang-metrics/costs.json`.
The Nix module option `services.sglangMetrics.costsFile` overrides
the path.

## Nix options

Set them in `nixos-pro5000/configuration.nix`:

```
services.sglangMetrics = {
  enable = true;
  endpoints = [ "127.0.0.1:30000" "127.0.0.1:31000" ];
  intervalMins = 5;
  costs.inputPerMioUSD = 3.0;
  costs.outputPerMioUSD = 15.0;
  # costsFile = "/path/to/costs.json";  # default:
  # ~/.local/share/sglang-metrics/costs.json
};
```

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

It is a rough guide. Set the costs file to the real prices of the
cloud API you replace. Tokens processed while the timer was not
running (at most one interval) are not counted.
