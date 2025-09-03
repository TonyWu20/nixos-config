# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, ... }:
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
    ];
    shell = pkgs.fish;
  };
}

