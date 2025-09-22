{ config, ... }: {
  # basic configuration of git, please change to your own
  imports = [
    ./default.nix
  ];
  home.username = "jerry";
  home.homeDirectory = "/home/jerry";
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
  home.sessionVariables.SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/nixos-config/sops/age/keys.txt";
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "jerrylizk3";
    userEmail = "jerrylizk3@gmail.com";
    delta = {
      enable = true;
    };
    extraConfig = {
      safe.directory = [
        "/export/gauss_shell"
      ];
    };
  };
  programs.ssh = {
    matchBlocks.gh = {
      host = "github.com";
      user = "git";
      hostname = "github.com";
      identityFile = config.sops.secrets."jerry-ssh/ssh.key".path;
    };
  };
  sops = {
    defaultSopsFile = ../sops/secrets/my_secrets.yaml;
    age.sshKeyPaths = [ "/home/jerry/.ssh/id_ed25519" ];
    age.generateKey = false;
    secrets."tony-ssh/ssh.key" = {
      mode = "0400";
    };
    secrets."jerry-ssh/ssh.key" = {
      path = "/home/jerry/.ssh/id_ed25519";
      mode = "0400";
    };
  };
}
