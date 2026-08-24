{ lib, pkgs, ... }:
{
  imports = [
    ../cluster/hosts.nix
    ../nfs/node.nix
  ];

  # Single user: tony only (unlike modules/users.nix, which defines all three).
  users.users.tony = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqIz6gNydwx4jPWhusIUBHY0eWG92uVsl4zHsGdOCHG tony.w21@gmail.com= tony"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzp6pyWcJnx6btvH8yeLMLMBrkq0kpxwb9i8OuMRzE4 jerry@nixos-2"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtwiC0q/QY4mx8ioxS+dIn6bWWCe7r8V79+kH5MgWZU qiuyang@nixos-qiuyang"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrya8j0XoeQhKOFG/9lVcAlbD4k5NvGDVuvlOd0WYP0 tony.w21@gmail.com"
      "ssh-ed25519 AAAAC3NzaC11ZDI1NTE5AAAAIAdUqI5Qh4/LRgyN0/nTcSRhKjajoGknGyIhhvuDiFOH qiuyang@DM-20240524HWVQ"
    ];
    shell = pkgs.fish;
    uid = 1000;
  };

  # Group required by sops for the tony ssh key secret
  users.groups.nixGitUsers = {
    gid = 1008;
    members = [ "tony" ];
  };

  # Point to local binary cache on head node
  nix.settings = {
    substituters = lib.mkBefore [ "http://10.0.0.2" ];
    trusted-public-keys = [ "10.0.0.2:iIE9Q90BgaU/izk7x2F7+j/C5B2guzO0JULT2q2yylI=" ];
  };
}
