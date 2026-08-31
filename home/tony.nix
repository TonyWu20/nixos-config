{ config, lib, pkgs, ... }:
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
  apiSecrets = lib.listToAttrs (map
    (var: {
      name = "${var}";
      value = { };
    })
    secretNames);
in
{
  imports = [
    ./tony-base.nix
    ../rime
    ../neomutt
    ../waybar
    ../fcitx5/home.nix
    ../tex
    ../hypr
    ../tofi
  ];

  sops.secrets = apiSecrets;
  home.packages = with pkgs; [
    terminal-browser
  ];
}
