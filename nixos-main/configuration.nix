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
    interfaces.enp6s0.ipv4.addresses = [{
      address = "10.0.0.2";
      prefixLength = 24;
    }];
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

  system.stateVersion = "24.11";
}
