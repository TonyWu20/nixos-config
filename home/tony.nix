{ config, ... }: {
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
    secrets."tony-ssh/ssh.key" = {
      mode = "0400";
    };
  };
}
