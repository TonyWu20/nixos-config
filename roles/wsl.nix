# WSL machine role: NixOS-WSL support module.
#
# wsl.enable makes NixOS-WSL write /etc/wsl.conf and set up systemd,
# interop, and recovery hooks for the Windows WSL runtime. Without it,
# a rebuilt system is plain NixOS and the distro breaks.
{ inputs, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl.enable = true;
}
