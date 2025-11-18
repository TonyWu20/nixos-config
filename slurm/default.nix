{ pkgs, config, ... }:
let
  host = "nixos";
in
{
  services.slurm = {
    client.enable = true;
    enableStools = false;
    # controlMachine = host;
    dbdserver = {
      enable = true;
      dbdHost = host;
      extraConfig = ''
        PidFile=/run/slurmdbd.pid
        StorageHost=localhost
      '';
    };
    nodeName = [
      "nixos CPUs=44 Boards=1 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=1 RealMemory=128699 Gres=gpu:nvidia_geforce_gtx_1070:1,shard:2"
      "nixos-2 CPUs=88 Boards=1 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=2 RealMemory=128676 Gres=gpu:nvidia_geforce_gtx_1080_ti:1,shard:4"
      "nixos-3 CPUs=88 Boards=1 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=2 RealMemory=128676 Gres=gpu:nvidia_geforce_gtx_1070:1,shard:2"
    ];
    clusterName = "nixostest";
    partitionName = [ "debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP OverSubscribe=YES" ];
    extraConfig = builtins.readFile ./slurm.conf;
    procTrackType = "proctrack/cgroup";
  };
  # systemd.services.slurmctld = {
  #   preStart = ''
  #     # Delay starting so that `slurmdbd.service` can settle.
  #     sleep 1
  #   '';
  #   requires = [ "munged.service" ];
  #   # requires = [ "slurmdbd.service" ];
  #   serviceConfig = {
  #     User = "slurm";
  #     Group = "slurm";
  #   };
  # };
  networking.firewall.allowedTCPPorts = [ 6817 6818 ];
  networking.firewall.allowedTCPPortRanges = [{ from = 50001; to = 63000; }];
  networking.firewall.trustedInterfaces = [ "enp6s0" ];

  environment.variables.SLURM_CONF = builtins.concatStringsSep "/" [ config.services.slurm.etcSlurm "slurm.conf" ];
}
