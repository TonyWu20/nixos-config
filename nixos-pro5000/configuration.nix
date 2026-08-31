{ pkgs, lib, config, ... }:
{
  imports = [
    ../modules/core.nix
    ./hardware-configuration.nix
  ];

  # The RTX PRO 5000 Blackwell needs the open kernel modules. The closed
  # modules fail with "requires use of the NVIDIA open kernel modules".
  # core.nix pins 580.142 for the Pascal cards, and its open build is broken
  # (it fetches the nvidia-settings source). Use the nixpkgs-maintained
  # latest driver (610.57.04) for this machine only.
  hardware.nvidia = {
    open = lib.mkForce true;
    package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.latest;
  };

  networking = {
    hostName = "nixos-pro5000";
    domain = "nixCluster";
    nameservers = [ "10.0.0.3" ];
    interfaces.enp11s0 = {
      mtu = 9000;
      ipv4.addresses = [{
        address = "10.0.0.6";
        prefixLength = 24;
      }];
    };
    firewall.trustedInterfaces = [ "enp11s0" ];
  };

  # Register the cluster DNS server with resolvconf. The DNS/NAT gateway is
  # nixos-2 (10.0.0.3). The stock path (network-local-commands.service pushes
  # networking.nameservers into resolvconf) can be dropped at boot: an
  # ordering cycle with the NFS mounts makes systemd delete that job, leaving
  # /etc/resolv.conf with no nameserver and breaking DNS. This service is a
  # dependency of multi-user.target, not of network.target, so the boot-cycle
  # resolution cannot drop it. It registers the "static" interface, which
  # resolvconf then folds into /etc/resolv.conf.
  systemd.services.cluster-resolvconf = {
    description = "Register cluster DNS server with resolvconf";
    after = [ "resolvconf.service" ];
    wants = [ "resolvconf.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.openresolv}/sbin/resolvconf -m 1 -a static <<EOF
      nameserver 10.0.0.3
      EOF
    '';
  };

  # Default route via nixos-2 (10.0.0.3), the cluster NAT/DNS gateway. This
  # machine has no working wifi uplink of its own, so the LAN gateway is its
  # only path to the internet.
  systemd.services.cluster-default-route = {
    description = "Install default route via nixos-2";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${pkgs.iproute2}/bin/ip route replace default via 10.0.0.3 dev enp11s0 metric 100";
    };
  };

  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];
  services.slurm.extraConfigPaths = [ ../slurm/nixos-pro5000 ];

  # Persist SGLang /metrics across sessions so token usage and the
  # local-serving savings accumulate in /var/lib/sglang-metrics.
  services.sglangMetrics = {
    enable = true;
    endpoints = [ "127.0.0.1:30000" "127.0.0.1:31000" ];
  };

  system.stateVersion = "25.05";
}
