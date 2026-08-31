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
  rate, and the estimated cloud API cost this local serving saved.
  The wrapper uses the prices set in the Nix module.

- `sglang-usage sessions` — per-session breakdown (start, end,
  prompt tokens, generation tokens, requests, cached tokens).

- `sglang-usage scrape --db PATH --endpoint HOST:PORT` — run one
  collection pass by hand (`sudo systemctl start
  sglang-metrics-collect` works too).

- `sglang-usage report --json` — machine-readable output.

## Report flags

- `--input-price N` / `--output-price N` — USD per million tokens.
  Defaults are 3.0 / 15.0. Match them to the API you replace.

- `--metrics a,b,c` — change which metric names the report reads.

## Nix options

Set them in `nixos-pro5000/configuration.nix`:

```
services.sglangMetrics = {
  enable = true;
  endpoints = [ "127.0.0.1:30000" "127.0.0.1:31000" ];
  intervalMins = 5;
  costs.inputPerMioUSD = 3.0;
  costs.outputPerMioUSD = 15.0;
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

The report computes:

```
savings = prompt_tokens/1e6 * input_price + generation_tokens/1e6 * output_price
```

It is a rough guide. Set `costs` to the real prices of the cloud API
you replace. Tokens processed while the timer was not running (at
most one interval) are not counted.
