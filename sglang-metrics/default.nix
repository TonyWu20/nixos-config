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
  reportBin = pkgs.writeShellScriptBin "sglang-usage-report" ''
    exec ${bin}/bin/sglang-usage report \
      --db ${cfg.dbPath} \
      --input-price ${lib.toString (cfg.costs.inputPerMioUSD or 3.0)} \
      --output-price ${lib.toString (cfg.costs.outputPerMioUSD or 15.0)} \
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

    costs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.float);
      default = {
        inputPerMioUSD = 3.0;
        outputPerMioUSD = 15.0;
      };
      description = ''
        Prices for the "estimated savings" line of the report, in USD
        per million tokens. Set `inputPerMioUSD` and `outputPerMioUSD`
        to the prices of the cloud API you replace with local serving.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ bin reportBin ];

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
