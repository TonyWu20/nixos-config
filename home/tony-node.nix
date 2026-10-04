{ lib, config, rushi-config, ... }:
let
  secretNames = [
    "mineru_token"
    "hf_token"
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
  ];

  sops.secrets = apiSecrets;
  programs.ssh.settings = {
    master = {
      host = "master";
      user = "tony";
      hostname = "10.0.0.2";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
  };
  programs.rushi = {
    enable = true;
    package = rushi-config.packages.x86_64-linux.rushi;
    enableTelevisionIntegration = true;
  };
}
