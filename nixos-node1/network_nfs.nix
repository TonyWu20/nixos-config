{ ... }: {
  # Open ports in the firewall.
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" "e3918db483c6bfed" ];
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.3";
    prefixLength = 24;
  }];
  networking.hosts = {
    "10.0.0.3" = [ "nixos-2" ];
    "10.0.0.2" = [ "nixos" ];
  };
  fileSystems = {
    "/export/castep_jobs" = {
      device = "10.0.0.2:/castep_jobs";
      fsType = "nfs";
    };
    "/export/g16" = {
      device = "10.0.0.2:/g16";
      fsType = "nfs";
    };
    "/export/gauss_shell" = {
      device = "10.0.0.2:/gauss_shell";
      fsType = "nfs";
    };
    "/export/gaussian_jobs" = {
      device = "10.0.0.2:/gaussian_jobs";
      fsType = "nfs";
    };
  };

}
