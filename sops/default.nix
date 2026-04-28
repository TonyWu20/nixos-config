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
    secrets."tony-ssh/ssh.key" = {
      mode = "0440";
      group = config.users.groups.nixGitUsers.name;
    };
    secrets."jerry-ssh/ssh.key" = {
      mode = "0440";
      group = config.users.groups.nixGitUsers.name;
    };
    secrets."dev_vars" = {
      poe_chatbot_api = { };
      yunwu_claude_api = { };
      foxcode_claude_token = { };
      xcode_best_claude_token = { };
      claude_zz_token = { };
      telegram_bot_token = { };
      telegram_user_id = { };
      discord_bot_token = { };
      discord_claude_channel_id = { };
      discord_inspect_channel_id = { };
      discord_notify_user_ids = { };
      discord_summary_channel_id = { };
      deepseek_token = { };
    };
  };
}
