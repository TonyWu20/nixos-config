# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ lib, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ../configuration-common.nix
      ./hardware-configuration.nix
      ./network_nfs.nix
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
  networking.hostName = "nixos-2"; # Define your hostname.
  networking.domain = "nixCluster"; # Define your domain.
}

