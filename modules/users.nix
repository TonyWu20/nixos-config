# modules/users.nix — User and group definitions (cluster-wide)
{ pkgs, ... }:

{
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

  users.users.jerry = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbR3ws1aSpPFp9wblhtHpJk3F5qyD/lqwjiXTc0zLku root@JerryDK"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrya8j0XoeQhKOFG/9lVcAlbD4k5NvGDVuvlOd0WYP0 tony.w21@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtwiC0q/QY4mx8ioxS+dIn6bWWCe7r8V79+kH5MgWZU qiuyang@nixos-qiuyang"
    ];
    shell = pkgs.fish;
    uid = 1001;
  };

  users.users.qiuyang = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqIz6gNydwx4jPWhusIUBHY0eWG92uVsl4zHsGdOCHG tony.w21@gmail.com= tony"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzp6pyWcJnx6btvH8yeLMLMBrkq0kpxwb9i8OuMRzE4 jerry@nixos-2"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrya8j0XoeQhKOFG/9lVcAlbD4k5NvGDVuvlOd0WYP0 tony.w21@gmail.com"
    ];
    shell = pkgs.fish;
    uid = 1002;
  };

  users.users.gaussian = {
    isSystemUser = true;
    uid = 45500;
    group = "gaussian";
  };

  users.groups = {
    nixGitUsers = {
      gid = 1008;
      members = [ "tony" "jerry" "qiuyang" ];
    };
    gaussian = {
      gid = 1009;
      members = [ "tony" "jerry" "qiuyang" "gaussian" ];
    };
  };
}
