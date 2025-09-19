{ config, ... }: {
  # basic configuration of git, please change to your own
  imports = [
    ./default.nix
  ];
  home.username = "tony";
  home.homeDirectory = "/home/tony";
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
  home.sessionVariables.SOPS_AGE_KEY_FILE = "/home/tony/nixos-config/sops/age/keys.txt";
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "TonyWu20";
    userEmail = "tony.w21@gmail.com";
    delta = {
      enable = true;
    };
    extraConfig = {
      safe.directory = [
        "/home/tony/Downloads/gauss_shell"
      ];
    };
  };
  programs.ssh = {
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
