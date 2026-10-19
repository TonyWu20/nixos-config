# Home profile for user jojo, on j-wsl (NixOS in WSL on j's machine).
#
# Standard base profile (fish, starship, tmux, wezterm, television,
# nvim, ...) plus the shared home-manager modules. The github ssh key
# is a sops secret. The sops-nix user service decrypts it at login.
{ config, ... }: {
  imports = [
    ./default.nix
  ];

  home.username = "jojo";
  home.homeDirectory = "/home/jojo";
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];

  # The shared age key file (sops/age/keys.txt) is untracked in the
  # repo. It is placed out-of-band on j-wsl next to the repo clone.
  # sops.age.keyFile drives the sops-nix user service. The session
  # variable covers sops CLI use, same as the qiuyang profile.
  home.sessionVariables.SOPS_AGE_KEY_FILE = "/home/jojo/nixos-config/sops/age/keys.txt";

  sops = {
    defaultSopsFile = ../sops/secrets/my_secrets.yaml;
    age.keyFile = "/home/jojo/nixos-config/sops/age/keys.txt";
    secrets."tony-ssh/ssh.key" = {
      mode = "0400";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # Git identity is j's github-j account.
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "jojo";
        email = "joycelynchou01@gmail.com";
      };
      core = {
        quotepath = false;
      };
    };
  };

  programs.ssh = {
    enableDefaultConfig = false;
    settings = {
      # TonyWu20 repo access reuses the cluster tony-ssh key. It is a
      # sops secret, decrypted by the sops-nix user service at login.
      gh = {
        host = "github.com";
        user = "git";
        hostname = "github.com";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      github = {
        host = "github.com";
        user = "git";
        hostname = "github.com";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
    };
  };

  # No udisks2 on j-wsl, so the udiskie autostart would only fail.
  services.udiskie.enable = false;

  # No cluster API base URLs or discord host on j-wsl.
  custom.nixosConfig.fish.enableStaticEnvExports = false;
}
