{ lib, pkgs, ... }:
let
  llama-cpp-src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b8913";
    hash = "sha256-lY39EKxzx6wRc2yC3hGqHQxs+ljXbyqu8sJrjBJi6uM=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };
in
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

  services.dnsmasq = {
    enable = true;
    settings = {
      log-queries = true;
      port = 53;
      interface = "enp6s0";
      no-resolv = true;
      server = [ "144.214.2.32" "8.8.8.8" "1.1.1.1" ];
      localservice = false;
    };
  };

  services.dante = {
    enable = true;
    config = ''
      logoutput: /var/log/sockd.log
      internal: 10.0.0.3 port = 1080
      external: wlp0s20u4i2
      clientmethod: none
      socksmethod: none
      user.privileged: root
      user.notprivileged: nobody
      client pass { from: 0.0.0.0/0 to: 0.0.0.0/0 }
      socks pass {
          from: 0.0.0.0/0 to: 0.0.0.0/0
          command: bind connect udpassociate
          log: connect error
      }
      socks pass {
          from: 0.0.0.0/0 to: 0.0.0.0/0
          protocol: tcp udp
          command: bindreply udpreply
          log: connect error
      }
    '';
  };

  environment.systemPackages = with pkgs; [
    (llama-cpp.overrideAttrs (_: rec {
      version = "8913";
      cudaSupport = true;
      src = llama-cpp-src;
      npmDepsHash = "sha256-RAFtsbBGBjteCt5yXhrmHL39rIDJMCFBETgzId2eRRk=";
    }))
    litellm
  ];

  system.stateVersion = "24.11";
}
