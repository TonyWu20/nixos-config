{ config, ... }: {
  # basic configuration of git, please change to your own
  imports = [
    ./default.nix
  ];
  home.username = "qiuyang";
  home.homeDirectory = "/home/qiuyang";
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
  home.sessionVariables.SOPS_AGE_KEY_FILE = "/home/qiuyang/nixos-config/sops/age/keys.txt";
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "TonyWu20";
    userEmail = "tony.w21@gmail.com";
    delta = {
      enable = true;
    };
  };
  programs.ssh = {
    matchBlocks.gh = {
      host = "github.com";
      user = "git";
      hostname = "github.com";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
    matchBlocks.master = {
      host = "master";
      user = "tony";
      hostname = "10.0.0.2";
      identityFile = config.sops.secrets."qiuyang-ssh/ssh.key".path;
    };
    matchBlocks.node1 = {
      host = "node1";
      user = "tony";
      hostname = "10.0.0.3";
      identityFile = config.sops.secrets."qiuyang-ssh/ssh.key".path;
    };
  };
  sops = {
    defaultSopsFile = ../sops/secrets/my_secrets.yaml;
    age.sshKeyPaths = [ "/home/qiuyang/.ssh/id_ed25519" ];
    age.generateKey = true;
    secrets."tony-ssh/ssh.key" = {
      mode = "0400";
    };
    secrets."qiuyang-ssh/ssh.key" = {
      mode = "0400";
    };
  };
}
