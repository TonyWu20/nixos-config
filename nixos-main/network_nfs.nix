{ ... }: {
  # Open ports in the firewall.
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.2";
    prefixLength = 24;
  }];
  networking.hosts = {
    "10.0.0.4" = [ "nixos-3" ];
    "10.0.0.3" = [ "nixos-2" ];
    "10.0.0.2" = [ "nixos" ];
  };
  fileSystems = {
    "/export/castep_jobs" = {
      device = "/home/tony/Downloads/castep_jobs";
      options = [ "bind" "exec" ];
      fsType = "nfs";
    };
    "/export/gauss_shell" = {
      device = "/home/tony/Downloads/gauss_shell";
      options = [ "bind" "exec" ];
      fsType = "nfs";
    };
    "/export/g16" = {
      device = "/home/tony/Downloads/g16";
      options = [ "bind" "exec" "gid=1009" "mode=0770" ];
      fsType = "nfs";
    };
    "/export/gaussian_jobs" = {
      device = "localhost:/gaussian_jobs";
      options = [ "bind" "exec" "gid=1009" "mode=0770" ];
      fsType = "nfs";
    };
    "/export/Potentials" = {
      device = "/home/tony/Downloads/Potentials";
      options = [ "bind" "mode=0770" ];
      fsType = "nfs";
    };
  };
  services.nfs.server = {
    enable = true;
    exports = ''
      /export         *(rw,fsid=0,no_subtree_check)
      /export/castep_jobs         *(rw,no_subtree_check,insecure,nohide)
      /export/gauss_shell         *(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=45500,anongid=1009)
      /export/g16         *(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=45500,anongid=1009)
      /export/gaussian_jobs         *(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=45500,anongid=1009)
      /export/Potentials         *(rw,no_subtree_check,insecure,nohide)
    '';
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
  };

}
