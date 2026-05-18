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
  # basic configuration of git, please change to your own
  imports = [
    ./default.nix
    ../rime
    ../neomutt
    ../waybar
    ../fcitx5/home.nix
    ../tex
    ../hypr
    ../tofi
  ];
  home.username = "tony";
  home.homeDirectory = "/home/tony";
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
  home.sessionVariables.SOPS_AGE_KEY_FILE = "/home/tony/nixos-config/sops/age/keys.txt";

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "TonyWu20";
        email = "tony.w21@gmail.com";
      };
      core = {
        quotepath = false;
      };
      extraConfig = {
        safe.directory = [
          "/home/tony/Downloads/gauss_shell"
        ];
      };
    };
  };
  programs.ssh = {
    enableDefaultConfig = false;
    matchBlocks.gh = {
      host = "github.com";
      user = "git";
      hostname = "github.com";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
  };
  sops = {
    defaultSopsFile = ../sops/secrets/my_secrets.yaml;
    age.sshKeyPaths = [ "/home/tony/.ssh/id_ed25519" ];
    age.generateKey = false;
    secrets = dev_vars //
      {
        "tony-ssh/ssh.key" = {
          mode = "0400";
        };
      };
  };
}
