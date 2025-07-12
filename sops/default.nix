{ config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets/my_secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.generateKey = false;
    secrets."munge/munge.key" = {
      reloadUnits = [ "munged.service" ];
      owner = config.systemd.services.munged.serviceConfig.User;
      group = config.systemd.services.munged.serviceConfig.Group;
      mode = "0400";
    };
  };
}
