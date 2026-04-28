# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, lib, ... }:
let
  gres_conf = ../slurm/nixos-main/gres.conf;
in
{
  services = {
    dnsmasq = {
      enable = false;
      settings = {
        port = 53;
        listen-address = "198.18.0.1";
        no-resolv = true;
        server = [ "144.214.2.32" "8.8.8.8" "1.1.1.1" ];
      };
    };
    # Enable the Dante SOCKS5 server
    dante = {
      enable = false;
      config = ''
        logoutput: /var/log/sockd.log
        internal: 10.0.0.2 port = 1080
        external: wlp0s20u11  # Your internet-facing interface

        clientmethod: none
        socksmethod: none

        user.privileged: root
        user.notprivileged: nobody

        client pass {
            from: 10.0.0.2/0 to: 0.0.0.0/0
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
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };
    slurm.extraConfigPaths = [
      ../slurm/nixos-main
    ];
  };

  # Open the port in the firewall

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  imports =
    [
      # Include the results of the hardware scan.
      ../configuration-common.nix
      ./hardware-configuration.nix
      ./network_nfs.nix
      ./slurm.nix
      ./cache.nix
    ];
  networking = {
    hostName = "nixos"; # Define your hostname.
    domain = "nixCluster";
    nat = {
      enable = true;
      externalInterface = "wlp0s20u11";
      internalInterfaces = [ "lo" ];
    };
    networkmanager.insertNameservers = [ "10.0.0.3" ];
    nameservers = [ "10.0.0.3" "127.0.0.1" ];
    firewall.extraCommands = ''
      iptables -A FORWARD -i enp6s0 -o wlp0s20u11 -j ACCEPT
      iptables -t nat -A POSTROUTING -o wlp0s20u11 -j MASQUERADE
    '';
  }; # Define your domain.
  # nixpkgs.hostPlatform = {
  #   gcc.arch = "broadwell";
  #   gcc.tune = "broadwell";
  #   system = "x86_64-linux";
  # };
  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "gccarch-broadwell" "kvm" ];
  programs.firefox.enable = true;
  programs.hyprland.enable = true;
  environment.systemPackages = with pkgs; [
    litellm
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

