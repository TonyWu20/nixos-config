# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ lib, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ../configuration-common.nix
      ./hardware-configuration.nix
      ./network_nfs.nix
      ../nfs/node.nix
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
  services.slurm.extraConfigPaths = [ ../slurm/nixos-node1 ];
  environment.systemPackages = with pkgs; [
    (llama-cpp.overrideAttrs (
      _: rec{
        version = "8913";
        cudaSupport = true;
        src = fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          tag = "b${version}";
          hash = "sha256-lY39EKxzx6wRc2yC3hGqHQxs+ljXbyqu8sJrjBJi6uM=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > $out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-RAFtsbBGBjteCt5yXhrmHL39rIDJMCFBETgzId2eRRk=";
      }
    )
    )
    litellm
  ];
  services = {
    dnsmasq = {
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
    # Enable the Dante SOCKS5 server
    dante = {
      enable = true;
      config = ''
        logoutput: /var/log/sockd.log
        internal: 10.0.0.3 port = 1080
        external: wlp0s20u4i2  # Your internet-facing interface

        clientmethod: none
        socksmethod: none

        user.privileged: root
        user.notprivileged: nobody

        client pass {
            from: 0.0.0.0/0 to: 0.0.0.0/0
        }

        # Allow anyone from the local network to connect
        socks pass {
            from: 0.0.0.0/0 to: 0.0.0.0/0
            command: bind connect udpassociate
            log: connect error
        }

        # Allow forwarding of both TCP and UDP
        socks pass {
            from: 0.0.0.0/0 to: 0.0.0.0/0
            protocol: tcp udp
            command: bindreply udpreply
            log: connect error
        }
      '';
    };
  };

}

