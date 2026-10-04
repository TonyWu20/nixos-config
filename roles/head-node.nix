{ config, lib, pkgs, ... }: {
  imports = [
    ../cluster/hosts.nix
    ../modules/users.nix
    ../nixos-main/slurm.nix
    ../nixos-main/cache.nix
    ../nfs/node.nix
  ];

  # Dev ports (dashboard, dev servers, Webmin)
  networking.firewall.allowedTCPPorts = [ 8000 8080 10000 ];

  # Desktop / Hyprland
  programs.hyprland.enable = true;
  #  programs.firefox.enable = true;
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
