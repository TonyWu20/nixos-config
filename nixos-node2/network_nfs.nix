{ ... }: {
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.4";
    prefixLength = 24;
  }];
}
