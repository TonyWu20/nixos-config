# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, lib, ... }:
let
  gres_conf = ../slurm/nixos-main/gres.conf;
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ../configuration-common.nix
      ./hardware-configuration.nix
      ./network_nfs.nix
      ./slurm.nix
      ./cache.nix
    ];
  networking.hostName = "nixos"; # Define your hostname.
  networking.domain = "nixCluster"; # Define your domain.
  # nixpkgs.hostPlatform = {
  #   gcc.arch = "broadwell";
  #   gcc.tune = "broadwell";
  #   system = "x86_64-linux";
  # };
  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "gccarch-broadwell" "kvm" ];
  programs.firefox.enable = true;
  programs.hyprland.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };
  services.slurm.extraConfigPaths = [
    ../slurm/nixos-main
  ];
  nix = {
    settings = {
      substituters = lib.mkBefore [
        "http://10.0.0.2"
      ];
      trusted-public-keys = [
        "10.0.0.2:iIE9Q90BgaU/izk7x2F7+j/C5B2guzO0JULT2q2yylI="
      ];
    };
  };
}

