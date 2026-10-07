# 2026-10-05 - Split the catppuccin cpu_ram and disk status modules

## Context

The tmux config loaded two catppuccin builds at the same time.
The home-manager module loaded the build it owns.
The tmux plugins list also loaded the nixpkgs 2.1.3 build.

The two builds overwrote each other's options.
The cpu_ram and disk module definitions stayed in extraConfig.
They ran in the same shell as the plugin's last built-in module.

The shell-local MODULE_NAME carried into the module definitions.
The status-right lines used set -agF, which froze the value at set-time.

## Decisions

- Remove tmuxPlugins.catppuccin from the tmux plugins list.
  The home-manager catppuccin module loads the build it owns.
  tmux/default.nix takes catppuccinPkg from catppuccin.sources.tmux.
  It falls back to the nixpkgs build when that module is out of scope.
- Put the cpu_ram and disk module definitions in their own .conf files.
  Each file is a writeTextFile derivation.
  extraConfig sources each file after the catppuccin plugin loads.
  A separate file stops the shell-local MODULE_NAME from carrying over.
- Use set -ag for the cpu_ram and disk status-right lines.
  The -ag form keeps a live #{E:...} reference.
  The value refreshes each status-interval.
  The -agF form expanded the module content at set-time and froze it.
- Keep the cpu and ram value in one tmux env var, @cpu_ram_text.
  A background run-shell loop updates it every 5 s.
  The module text reads the var, so one spawn serves each refresh.

## Verification

On a live tmux server, @catppuccin_status_cpu_ram built with macchiato colors.
The border used the macchiato yellow #eed49f and the value rendered green.
The value updated live.
The cpu sample went from 1.8% to 7.1%.
The full status bar rendered every module in the macchiato theme.

## Note

The disk module df reads /dev/disk/by-label/nixos.
That label is absent on this host.
The labels here are NIXBOOT, NIXROOT, and swap.
The disk text renders empty on this host, but the border still shows.
This is a data issue, separate from the module fix.
