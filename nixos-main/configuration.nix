# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ ... }:
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

}

