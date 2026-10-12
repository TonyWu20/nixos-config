# Home profile for user jojo, on j-wsl (NixOS in WSL on j's machine).
#
# Standard base profile (fish, starship, tmux, wezterm, television,
# nvim, ...) plus the shared home-manager modules. No sops: j-wsl has
# no age keys and no sops-nix setup.
{ config, ... }: {
  imports = [
    ./default.nix
  ];

  home.username = "jojo";
  home.homeDirectory = "/home/jojo";
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];

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
      # sops secret, so it is placed out-of-band by the deploy step,
      # not managed by home-manager.
      gh = {
        host = "github.com";
        user = "git";
        hostname = "github.com";
        identityFile = "/home/jojo/.ssh/id_github_tony";
      };
      github = {
        host = "github.com";
        user = "git";
        hostname = "github.com";
        identityFile = "/home/jojo/.ssh/id_github_tony";
      };
    };
  };

  # No udisks2 on j-wsl, so the udiskie autostart would only fail.
  services.udiskie.enable = false;

  # No cluster API base URLs or discord host on j-wsl.
  custom.nixosConfig.fish.enableStaticEnvExports = false;
}
