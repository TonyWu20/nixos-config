{ config, ... }:
{
  imports = [
    ./tony-base.nix
  ];

  programs.ssh.settings = {
    master = {
      host = "master";
      user = "tony";
      hostname = "10.0.0.2";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
  };
}
