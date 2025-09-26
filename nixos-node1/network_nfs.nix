{ ... }: {
  # Open ports in the firewall.
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" "e3918db483c6bfed" ];
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.3";
    prefixLength = 24;
  }];
  networking.hosts = {
    "10.0.0.4" = [ "nixos-3" ];
    "10.0.0.3" = [ "nixos-2" ];
    "10.0.0.2" = [ "nixos" ];
  };
}
