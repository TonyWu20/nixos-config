{ pkgs, config, ... }:
let
  # One-shot CPU+RAM snapshot script. A background run-shell loop calls
  # this every 5 s and pushes the result into a tmux env var, so the
  # status bar shows one process spawn per refresh instead of 24.
  cpuStatusScript = pkgs.writeTextFile {
    name = "tmux-cpu-status";
    destination = "/bin/tmux-cpu-status";
    executable = true;
    text = builtins.readFile ./cpu_status.sh;
  };

  # The catppuccin build the home-manager catppuccin module actually loads.
  # Fall back to the nixpkgs build if that module is not in scope. Sourcing
  # status_module.conf from the loaded build keeps the module defs aligned
  # with the theme that is really on the bar.
  catppuccinPkg =
    let cp = config.catppuccin or { };
    in
    if cp ? sources
    then cp.sources.tmux
    else pkgs.tmuxPlugins.catppuccin;
  catppuccinRoot = "${catppuccinPkg}/share/tmux-plugins/catppuccin";

  # CPU/RAM module, in its own file, mirroring catppuccin's status/*.conf.
  # It is sourced (not inlined) so the shell-local MODULE_NAME that the
  # plugin's last built-in module leaves behind does not leak into this def.
  # The text field reads the env var the background loop below maintains, so
  # only one process is spawned per refresh cycle.
  cpuRamModule = pkgs.writeTextFile {
    name = "tmux-cpp-cpu-ram";
    destination = "/bin/tmux-cpp-cpu-ram.conf";
    text = ''
      %hidden MODULE_NAME="cpu_ram"
      set -g "@catppuccin_''${MODULE_NAME}_icon" "⚡ "
      set -agF "@catppuccin_''${MODULE_NAME}_color" "#{E:@thm_yellow}"
      set -g "@catppuccin_''${MODULE_NAME}_text" "#{E:@cpu_ram_text}"
      source "${catppuccinRoot}/utils/status_module.conf"
    '';
  };

  # Disk module, in its own file for the same reason as cpu_ram.
  diskModule = pkgs.writeTextFile {
    name = "tmux-cpp-disk";
    destination = "/bin/tmux-cpp-disk.conf";
    text = ''
      %hidden MODULE_NAME="disk"
      set -g "@catppuccin_''${MODULE_NAME}_icon" " "
      set -g "@catppuccin_''${MODULE_NAME}_color" "#{E:@thm_pink}"
      set -g "@catppuccin_''${MODULE_NAME}_text" "#(df /dev/disk/by-label/nixos -T | awk 'NR==2{print $4,"/",$2}')"
      source "${catppuccinRoot}/utils/status_module.conf"
    '';
  };
in
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    extraConfig = builtins.concatStringsSep "\n" [
      "set -g status-interval 5"
      (builtins.readFile ./tmux.conf)
      # The cpu_ram/disk modules, each in its own file, sourced now that the
      # catppuccin plugin has loaded (extraConfig runs after the plugin
      # run-shell lines). status_module.conf builds @catppuccin_status_cpu_ram
      # and @catppuccin_status_disk with the standard powerline borders.
      "source ${cpuRamModule}/bin/tmux-cpp-cpu-ram.conf"
      "source ${diskModule}/bin/tmux-cpp-disk.conf"
      # CPU/RAM: a background loop updates @cpu_ram_text every 5 s.
      ''
        run-shell -b 'PIDFILE="$HOME/.cache/tmux-cpu-status.pid"; if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then exit; fi; echo $$ > "$PIDFILE"; while true; do result=$(${cpuStatusScript}/bin/tmux-cpu-status); tmux set-environment -g @cpu_ram_text "$result" 2>/dev/null || break; sleep 5; done; rm -f "$PIDFILE"'
      ''
      # net-speed plugin: the Nix package ships with a #!/bin/bash shebang,
      # which fails on NixOS where /bin/bash does not exist. Load it via
      # an explicit bash invocation instead.
      ''
        run-shell "${pkgs.bash}/bin/bash ${pkgs.tmuxPlugins.net-speed}/share/tmux-plugins/net-speed/net_speed.tmux"
      ''
      (builtins.readFile ./tmux_catppuccin.conf)
    ];
    terminal = "xterm-256color";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.mode-indicator
      tmuxPlugins.yank
      tmuxPlugins.sensible
      # catppuccin is loaded by the home-manager catppuccin module
      # (catppuccin.sources.tmux). Listing it here as well loaded two
      # different catppuccin builds and they clobbered each other.
    ];
  };
}
