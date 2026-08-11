{ lib, pkgs, ... }:
{
  imports = [
    ./compute-node.nix
  ];

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

  networking.firewall = {
    allowedTCPPorts = [ 53 1080 ];
    allowedUDPPorts = [ 53 1080 ];
  };
}
