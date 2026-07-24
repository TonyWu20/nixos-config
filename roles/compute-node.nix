{ lib, ... }: {
  imports = [
    ../cluster/hosts.nix
    ../modules/users.nix
    ../nfs/node.nix
  ];

  # Point to local binary cache on head node
  nix.settings = {
    substituters = lib.mkBefore [ "http://10.0.0.2" ];
    trusted-public-keys = [ "10.0.0.2:iIE9Q90BgaU/izk7x2F7+j/C5B2guzO0JULT2q2yylI=" ];
  };
}
