{ ... }: {
  # Open ports in the firewall.
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.2";
    prefixLength = 24;
  }];
  networking.extraHosts = ''
    10.0.0.2 nixos
    10.0.0.3 nixos-2
  '';
  fileSystems = {
    "/export/castep_jobs" = {
      device = "/home/tony/Downloads/castep_jobs";
      options = [ "bind" "users" ];
      fsType = "nfs";
    };
    "/export/CASTEP-6.11-nixos" = {
      device = "/home/tony/Downloads/CASTEP-6.11-nixos";
      options = [ "bind" "users" ];
      fsType = "nfs";
    };
    "/export/CASTEP-25.12-nixos" = {
      device = "/home/tony/Downloads/CASTEP-25.12-nixos";
      options = [ "bind" "users" ];
      fsType = "nfs";
    };
    "/export/castep_devshell" = {
      device = "/home/tony/Downloads/castep_devshell";
      options = [ "bind" "users" ];
      fsType = "nfs";
    };
  };
  services.nfs.server = {
    enable = true;
    exports = ''
      /export       10.0.0.2(rw,fsid=0,no_subtree_check) 10.0.0.3(rw,fsid=0,no_subtree_check)
      /export/castep_jobs     *(rw,nohide,insecure,no_subtree_check)
      /export/CASTEP-25.12-nixos     *(rw,nohide,insecure,no_subtree_check)
      /export/CASTEP-6.11-nixos   *(rw,nohide,insecure,no_subtree_check)
      /export/castep_devshell     *(rw,nohide,insecure,no_subtree_check)
    '';
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
  };

}
