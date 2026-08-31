{ pkgs, lib, ... }:
{
  imports = [
    ../modules/core.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "nixos";
    domain = "nixCluster";
    networkmanager.insertNameservers = [ "10.0.0.3" ];
    nameservers = [ "10.0.0.3" "127.0.0.1" ];
    interfaces.enp6s0 =
      {
        mtu = 9000;
        ipv4.addresses = [{
          address = "10.0.0.2";
          prefixLength = 24;
        }];
      };
    nat = {
      enable = true;
      externalInterface = "wlp0s20u11";
      internalInterfaces = [ "lo" ];
    };
    firewall.extraCommands = ''
      iptables -A FORWARD -i enp6s0 -o wlp0s20u11 -j ACCEPT
      iptables -t nat -A POSTROUTING -o wlp0s20u11 -j MASQUERADE
    '';
  };
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];

  # Fallback default route via nixos-2 (10.0.0.3, the cluster NAT/DNS gateway),
  # used while this node's own wifi uplink is down. Metric 700 loses to
  # NetworkManager's wifi default (~600), so the wifi route wins whenever it
  # exists and this one is only used as a fallback.
  systemd.services.fallback-default-route = {
    description = "Install fallback default route via nixos-2";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${pkgs.iproute2}/bin/ip route replace default via 10.0.0.3 dev enp6s0 metric 700";
    };
  };

  system.stateVersion = "24.11";
}
