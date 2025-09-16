# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, lib, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ../configuration-common.nix
      ./hardware-configuration.nix
      ./network_nfs.nix
    ];
  # add user for jerry
  users.users.jerry = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbR3ws1aSpPFp9wblhtHpJk3F5qyD/lqwjiXTc0zLku root@JerryDK"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrya8j0XoeQhKOFG/9lVcAlbD4k5NvGDVuvlOd0WYP0 tony.w21@gmail.com"
    ];
    shell = pkgs.fish;
  };
  nix = {
    settings = {
      substituters = lib.mkForce [
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

