# SGLang metrics persistence.
#
# A systemd timer runs `sglang-usage scrape` every N minutes. It pulls
# /metrics from each configured SGLang endpoint and appends the usage
# counters to an append-only TSV file under /var/lib. The file survives
# SGLang restarts, so token usage accumulates across sessions.
#
# Use `sglang-usage report` to see cumulative totals and the estimate
# of the cloud API cost that local serving saved.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.sglangMetrics;

  bin = import ./package.nix { inherit pkgs; };

  # A second wrapper with the configured prices and db path baked in.
  fallbackIn = cfg.costs.default.input or 3.0;
  fallbackOut = cfg.costs.default.output or 15.0;

  # Every entry must have input and output prices.
  costsOk =
    let costs = cfg.costs;
    in lib.all (e:
      lib.isAttrs e
      && (builtins.hasAttr "input" e)
      && (builtins.hasAttr "output" e)
    ) (costs.models or [])
      && (!(costs ? default)
      || (lib.isAttrs costs.default
      && (builtins.hasAttr "input" costs.default)
      && (builtins.hasAttr "output" costs.default)));

  reportBin = pkgs.writeShellScriptBin "sglang-usage-report" ''
    exec ${bin}/bin/sglang-usage report \
      --db ${cfg.dbPath} \
      --costs-file ${cfg.costsFile} \
      --input-price ${lib.toString fallbackIn} \
      --output-price ${lib.toString fallbackOut} \
      "$@"
  '';

  endpointArgs = lib.concatStringsSep " "
    (lib.map (e: "--endpoint ${e}") cfg.endpoints);
  metricArgs = "--metrics ${lib.concatStringsSep "," cfg.metrics}";
in
{
  options.services.sglangMetrics = {
    enable = lib.mkEnableOption
      "periodic persistence of SGLang /metrics across sessions";

    endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "127.0.0.1:30000" "127.0.0.1:31000" ];
      description = ''
        SGLang endpoints to scrape, as HOST:PORT or NAME=HOST:PORT.
        The NAME part labels the data rows. The server must run with
        `enable-metrics: true`.
      '';
    };

    intervalMins = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Scrape period in minutes.";
    };

    dbPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sglang-metrics/usage.tsv";
      description = "Path of the append-only TSV data file.";
    };

    metrics = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sglang:prompt_tokens_total"
        "sglang:generation_tokens_total"
        "sglang:num_requests_total"
        "sglang:cached_tokens_total"
        "sglang:realtime_tokens_total"
        "sglang:backuped_tokens_total"
        "sglang:cache_hit_rate"
      ];
      description = "Metric names to persist on every scrape.";
    };

    costsFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/sglang-metrics/costs.json";
      description = ''
        Path to the JSON costs file the report uses for per-model
        prices. The module writes this file from the `costs` option
        at activation time. Set it to another path to use a file
        outside of Nix. If the file is missing at report time, the
        report falls back to the `costs` default prices.
      '';
    };

    costs = lib.mkOption {
      type = lib.types.attrs;
      default = {
        models = [
          { id = "Qwen3.8-Flash-Next-NVFP4"; input = 0.44; output = 1.32; cacheRead = 0.014; }
          { id = "Qwen3.8-27B-NVFP4"; input = 0.44; output = 1.32; cacheRead = 0.014; }
          { id = "Qwen3.8-27B-NVFP4-RTX5090-DSPARK"; input = 0.44; output = 1.32; cacheRead = 0.014; }
          { id = "Qwen3.8-27B-DAU-IQ4"; input = 1.74; output = 3.48; cacheRead = 0.145; }
          { id = "Qwen3.8-27B-DAU-Q8_0"; input = 1.74; output = 3.48; cacheRead = 0.145; }
          { id = "Qwen3.8-27B-GGUF-DFlash2-UD-Q6_K_XL"; input = 1.74; output = 3.48; cacheRead = 0.145; }
          { id = "Nail-Qwen3.6-35B-A3B"; input = 1.74; output = 3.48; cacheRead = 0.145; }
          { id = "deepseek-v4-pro"; input = 1.74; output = 3.48; cacheRead = 0.145; }
          { id = "deepseek-v4-flash"; input = 0.14; output = 0.28; cacheRead = 0.028; }
        ];
        default = { input = 3.0; output = 15.0; cacheRead = 0.3; };
      };
      description = ''
        Per-model prices in USD per 1M tokens. `models` is a list of
        `{ id, input, output, cacheRead? }`; `default` prices the
        models the list does not match. The module writes this table
        to the file named by `costsFile` at activation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ bin reportBin ];

    # The costs table the report reads, managed by Nix.
    environment.etc."sglang-metrics/costs.json" = {
      user = "root";
      group = "root";
      mode = "0444";
      text = if costsOk
      then builtins.toJSON cfg.costs
      else throw "services.sglangMetrics.costs: every models entry and default need input and output";
    };

    systemd.services.sglang-metrics-collect = {
      description = "Append SGLang /metrics counters to the usage database";
      serviceConfig = {
        Type = "oneshot";
        # Creates /var/lib/sglang-metrics. 0755 so users can read the
        # TSV file the root service writes.
        StateDirectory = "sglang-metrics";
        StateDirectoryMode = "0755";
        ExecStart =
          "${bin}/bin/sglang-usage scrape"
          + " --db ${cfg.dbPath}"
          + " ${endpointArgs}"
          + " ${metricArgs}";
      };
    };

    systemd.timers.sglang-metrics-collect = {
      description = "Periodic SGLang metrics collection";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # Fire once per minute after boot, then every intervalMins.
        OnBootSec = "1min";
        OnUnitActiveSec = "${lib.toString cfg.intervalMins}min";
        Unit = "sglang-metrics-collect.service";
      };
    };
  };
}
