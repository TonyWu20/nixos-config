{ pkgs, ... }: {
  imports = [
    ../modules/core.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "nixos-3";
    domain = "nixCluster";
    interfaces.enp6s0 =
      {
        mtu = 9000;
        ipv4.addresses = [{
          address = "10.0.0.4";
          prefixLength = 24;
        }];
      };
  };
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];
  services.slurm.extraConfigPaths = [ ../slurm/nixos-node2 ];

  system.stateVersion = "24.11";
  environment.systemPackages = with pkgs; [
    (llama-cpp.override { rpcSupport = true; })
  ];

}
