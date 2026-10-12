# j-wsl: NixOS running in WSL2 on j's Windows machine.
#
# Reached via `ssh j-wsl` (through j, 10.0.0.2 on j's side).
# Networking is managed by WSL, so no interfaces or DNS are set here.
# No host hardware, so there is no hardware-configuration.nix.
{ config, lib, pkgs, ... }:
{
  networking.hostName = "j-wsl";

  # When the distro is opened in Windows Terminal, land in jojo's shell.
  wsl.defaultUser = "jojo";

  nix.settings = {
    # Allow flake-based rebuilds from the cloned nixos-config repo.
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "nixos" "jojo" ];
    auto-optimise-store = true;
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  # Puts fish into /etc/shells so the user shells below pass the
  # shell check. Same babelfish practice as the cluster machines.
  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  users = {
    # j's user. Kept so j can still use the distro.
    # uid 1000 is the uid the distro created at install time.
    users.nixos = {
      isNormalUser = true;
      uid = 1000;
      shell = pkgs.fish;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAi873SRA/ztV8LidDtH47mOSd3m+xPoSeYFB0TK8WB6 j@j-ubuntu"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrya8j0XoeQhKOFG/9lVcAlbD4k5NvGDVuvlOd0WYP0 tony.w21@gmail.com"
      ];
    };

    # jojo's user: tony's account on this machine (ssh j-wsl, through j).
    # The NixOS-WSL module mkDefaults the default user to uid 1000;
    # that belongs to the installed nixos user, so jojo takes 1001.
    users.jojo = {
      isNormalUser = true;
      uid = 1001;
      shell = pkgs.fish;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrya8j0XoeQhKOFG/9lVcAlbD4k5NvGDVuvlOd0WYP0 tony.w21@gmail.com"
      ];
    };
  };

  # Ported from the hand-written /etc/nixos configuration of the
  # installed distro. Keeps /mnt/wsl a mount point so the WSL
  # automount of the Windows drives keeps working.
  systemd.services."wsl-mnt-guard" = {
    overrideStrategy = "asDropin";
    unitConfig.ConditionPathIsMountPoint = "/mnt/wsl";
    serviceConfig = {
      ExecStart = [ "" "${pkgs.coreutils}/bin/true" ];
      ExecStop = [ "" "-${pkgs.util-linux}/bin/mount --make-rslave /mnt/wsl" ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    iproute2
  ];

  # Match the installed NixOS-WSL distro.
  system.stateVersion = "26.05";
}
