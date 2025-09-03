{ ... }: {
  # Open ports in the firewall.
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" "e3918db483c6bfed" ];
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.3";
    prefixLength = 24;
  }];
  networking.extraHosts = ''
    10.0.0.3 nixos-2
    10.0.0.2 nixos
  '';
  fileSystems = {
    "/export/castep_jobs" = {
      device = "10.0.0.2:/castep_jobs";
      fsType = "nfs";
    };
    "/export/CASTEP-6.11-nixos" = {
      device = "10.0.0.2:/CASTEP-6.11-nixos";
      fsType = "nfs";
    };
    "/export/CASTEP-25.12-nixos" = {
      device = "10.0.0.2:/CASTEP-25.12-nixos";
      fsType = "nfs";
    };
    "/export/castep_devshell" = {
      device = "10.0.0.2:/castep_devshell";
      fsType = "nfs";
    };
  };

}
