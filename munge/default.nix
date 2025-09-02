{ config, ... }: {
  services.munge = {
    enable = true;
    password = config.sops.secrets."munge/munge.key".path;
  };
  systemd.services.munged = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
}
