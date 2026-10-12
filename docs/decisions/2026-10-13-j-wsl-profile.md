# 2026-10-13 - Add j-wsl (NixOS in WSL) as a flake machine with user jojo

## Context

j-wsl is a NixOS-WSL distribution (nix-community/NixOS-WSL) running in WSL2
on j's Windows machine. It is reachable from the cluster via
`ssh j-wsl` (user nixos, 10.0.0.2 on j's side, through proxyJump j).
The goal is a flake profile so the standard terminal settings
(fish, starship, tmux, my-nvim, catppuccin) can be deployed there
for a new user `jojo`.

## Decisions

- j-wsl gets its own machine entry in flake.nix via mkNixosSystem:
  configPath `./nixos-j-wsl/configuration.nix`, role `./roles/wsl.nix`,
  `enableFcitx5 = false`, and `homeImports = { jojo.imports = [ ./home/jojo.nix ]; }`.
- New flake input `nixos-wsl` (github:nix-community/NixOS-WSL, nixpkgs follows).
  The role module imports it and sets `wsl.enable = true`. Without this the
  rebuilt system loses /etc/wsl.conf handling and the distro breaks.
- The machine does not import modules/core.nix. It carries cluster-only
  settings (GPU, SLURM, munge, bootloader, NFS, zeroTier) that do not apply
  to WSL.
- jojo uses the full standard home profile (home/default.nix), same as jerry.
  `services.udiskie` is disabled for j-wsl because there is no udisks2.
- The shared home-manager modules for j-wsl exclude the pi stack
  (pi, pi-config). mkNixosSystem now takes a `homeSharedModules` argument
  that defaults to the full set, so existing machines are unchanged.
- The ssh entry `j-wsl` in nixos-main/home_ssh.nix switches
  user from `nixos` to `jojo`. The nixos user stays defined on the machine.
- `networking.hostName = "j-wsl"`. The NixOS-WSL wsl.conf hostname follows
  networking.hostName, so the distro hostname changes too.
- `wsl.defaultUser = "jojo"`: opening the distro in Windows Terminal
  lands in jojo's shell.
- jojo's git identity is the github-j account:
  `jojo` / `joycelynchou01@gmail.com` (taken from j's machine,
  the gitconfig global identity of the github-j ssh host).
- TonyWu20 repo access on j-wsl reuses the cluster tony-ssh key
  (sops secret tony-ssh/ssh.key, public key comment tony.w21@gmail.com).
  It is placed out-of-band at /root/.ssh/id_github_tony for the bootstrap
  build and at /home/jojo/.ssh/id_github_tony for jojo. jojo.nix points
  the ssh gh/github entries at it.
- j-wsl has no sops. The static env var exports in the fish init
  (API base URLs, discord host) are gated behind
  `custom.nixosConfig.fish.enableStaticEnvExports` (default true) and
  disabled in home/jojo.nix.
- j's `wsl-mnt-guard` systemd service is ported into
  nixos-j-wsl/configuration.nix.
- Deploy flow: commit and push, clone the repo on j-wsl to
  /home/jojo/nixos-config (as root, with the placed key), then
  `sudo nixos-rebuild switch --flake /home/jojo/nixos-config#j-wsl`
  on j-wsl, and `wsl --shutdown` on the Windows side to pick up the
  new system profile.

## Notes

- `nix eval .#nixosConfigurations.j-wsl.config.systemd.services --json`
  fails on this nixpkgs: the testing/service-runner.nix module (part of the
  standard module list) builds a `runner` script for every service and
  interpolates serviceConfig.ExecStart as a string. The getty module now
  sets console-getty's ExecStart to a list, so the coercion fails.
  Only full-attribute evaluation is affected; the system build is not.

## Commit scope

- The commit also removes the `programs.pi.coding-agent` block from
  home/default.nix. That in-progress working tree change is required by
  this machine: with the pi stack out of j-wsl's shared modules, the base
  profile must not reference `programs.pi`.
- Pre-existing in-progress changes are kept out of the commit and stay in
  the working tree: the terminal-browser-flake `nixpkgs.follows` input
  change, the refreshened rushi-config lock entries, and the
  rushi-sessions eventPreviewer tweak in home/tony.nix and
  home/tony-node.nix. A backup of the mixed state is at
  /tmp/inprogress_mixed_2026-10-13.patch on the build machine.
