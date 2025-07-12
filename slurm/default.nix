{ pkgs, config, ... }:
let
  host = "nixos";
in
{
  services.slurm = {
    client.enable = true;
    server.enable = true;
    enableStools = false;
    controlMachine = host;
    dbdserver = {
      enable = true;
      dbdHost = host;
      extraConfig = ''
        PidFile=/run/slurmdbd.pid
        StorageHost=localhost
      '';
    };
    nodeName = [
      "nixos CPUs=44 Boards=1 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=1 RealMemory=128699 Gres=gpu:nvidia_geforce_gtx_1070:1"
      "j-ubuntu NodeAddr=10.0.0.3 CPUs=88 RealMemory=128687 Sockets=2 CoresPerSocket=22 ThreadsPerCore=2"
    ];
    clusterName = "nixostest";
    partitionName = [ "debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP" ];
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
  networking.firewall.allowedTCPPortRanges = [{ from = 60001; to = 63000; }];
  environment.variables.SLURM_CONF = builtins.concatStringsSep "/" [ config.services.slurm.etcSlurm "slurm.conf" ];
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    ensureDatabases = [ "slurm_acct_db" ];
    ensureUsers = [{
      ensurePermissions = { "slurm_acct_db.*" = "ALL PRIVILEGES"; };
      name = "slurm";
    }];

    settings.mysqld = {
      bind-address = "localhost";

      # recommendations from: https://slurm.schedmd.com/accounting.html#mysql-configuration
      innodb_buffer_pool_size = "1024M";
      innodb_log_file_size = "64M";
      innodb_lock_wait_timeout = 900;
    };
  };
}
