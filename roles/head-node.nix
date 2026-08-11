{ config, lib, pkgs, ... }: {
  imports = [
    ../cluster/hosts.nix
    ../modules/users.nix
    ../nixos-main/slurm.nix
    ../nixos-main/cache.nix
  ];

  # NFS server exports
  services.nfs.server = {
    enable = true;
    exports = ''
      /export         *(rw,fsid=0,no_subtree_check,insecure)
      /export/castep_jobs         *(rw,no_subtree_check,insecure,nohide)
      /export/gauss_shell         *(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=45500,anongid=1009)
      /export/g16         *(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=45500,anongid=1009)
      /export/gaussian_jobs         *(rw,nohide,insecure,no_subtree_check,all_squash,anonuid=45500,anongid=1009)
      /export/Potentials         *(rw,no_subtree_check,insecure,nohide)
      /export/castep-rust-eigensolve *(rw,no_subtree_check,insecure,all_squash,sync,nohide,anonuid=1000,anongid=1008)
    '';
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  # NFS export bind mounts
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
    "/export/castep-rust-eigensolve" = {
      device = "/home/tony/programming/castep-rust-eigensolve";
      options = [ "bind" ];
      fsType = "nfs";
    };
  };

  # Dev ports (dashboard, dev servers, Webmin)
  networking.firewall.allowedTCPPorts = [ 8000 8080 10000 ];

  # Desktop / Hyprland
  programs.hyprland.enable = true;
  programs.firefox.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # NAT routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # SLURM controller extra config path
  services.slurm.extraConfigPaths = [ ../slurm/nixos-main ];

  # Binary cache (nix-serve + nginx proxy)
  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "gccarch-broadwell" "kvm" ];
}
