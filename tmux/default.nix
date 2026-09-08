{ pkgs, ... }: {
  home.packages = [
    # cpu plugin is loaded only by the guarded run-shell in extraConfig below,
    # so it is not listed in programs.tmux.plugins (which would also emit an
    # unconditional run-shell and source cpu.tmux a second time).
    pkgs.tmuxPlugins.cpu
  ];

  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./tmux.conf)
      ''
        %hidden MODULE_NAME="disk"
        set -g "@catppuccin_''${MODULE_NAME}_icon" " "
        set -gF "@catppuccin_''${MODULE_NAME}_color" "#{E:@thm_pink}"
        set -g "@catppuccin_''${MODULE_NAME}_text" "#(df /dev/disk/by-label/nixos -T | awk 'NR==2{print $4,"/",$2}')"

        source "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/utils/status_module.conf"
      ''
      ''
        run-shell 'if [ "$(tmux show-env -g TMUX_CPU_INITIALIZED 2>/dev/null)" = "" ]; then tmux set-env -g TMUX_CPU_INITIALIZED 1; ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux; fi'
      ''
      (builtins.readFile ./tmux_catppuccin.conf)
      # ''
      #   # tmux-agent-pane: agent pane status sidebar
      #   set-environment -g TMUX_PLUGIN_DIR "${pkgs.tmux-agent-pane}"
      #   run-shell 'if [ "$(tmux show-env -g TAP_INITIALIZED 2>/dev/null)" = "" ]; then tmux set-env -g TAP_INITIALIZED 1; ${pkgs.tmux-agent-pane}/bin/tmux-agent-pane.tmux; fi'
      # ''
    ];
    terminal = "xterm-256color";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.net-speed
      tmuxPlugins.mode-indicator
      tmuxPlugins.yank
      tmuxPlugins.sensible
      tmuxPlugins.catppuccin
    ];
  };
}
