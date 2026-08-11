{ pkgs, ... }:
{
  imports = [
    ../modules/core.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "nixos-2";
    domain = "nixCluster";
    interfaces.enp6s0.ipv4.addresses = [{
      address = "10.0.0.3";
      prefixLength = 24;
    }];
  };
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" "e3918db483c6bfed" ];

  services.slurm.extraConfigPaths = [ ../slurm/nixos-node1 ];



  environment.systemPackages = with pkgs; [
    llama-cpp
    litellm
  ];

  system.stateVersion = "24.11";
}
