{ config, lib, ... }:
let
  secretNames = [
    "poe_chatbot_api"
    "yunwu_claude_api"
    "foxcode_claude_token"
    "xcode_best_claude_token"
    "claude_zz_token"
    "telegram_bot_token"
    "telegram_user_id"
    "discord_bot_token"
    "discord_channel_id"
    "discord_inspect_channel_id"
    "discord_notify_user_ids"
    "discord_summary_channel_id"
    "deepseek_token"
  ];
  dev_vars = lib.listToAttrs (map
    (var: {
      name = "${var}";
      value = { }; # You can add sops options here (e.g., owner, group, mode)
    })
    secretNames);
in
{
  sops = {
    defaultSopsFile = ./secrets/my_secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.generateKey = false;
    secrets = dev_vars // {
      "munge/munge.key" = {
        reloadUnits = [ "munged.service" ];
        owner = config.systemd.services.munged.serviceConfig.User;
        group = config.systemd.services.munged.serviceConfig.Group;
        mode = "0400";
      };
      "tony-ssh/ssh.key" = {
        mode = "0440";
        group = config.users.groups.nixGitUsers.name;
      };
      "jerry-ssh/ssh.key" = {
        mode = "0440";
        group = config.users.groups.nixGitUsers.name;
      };
      "qiuyang-ssh/ssh.key" = {
        mode = "0440";
        group = config.users.groups.nixGitUsers.name;
      };
    };
  };
}
