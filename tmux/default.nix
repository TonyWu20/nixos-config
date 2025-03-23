{ config, pkgs, ... }: {
  programs.tmux = {
    sensibleOnTop = true;
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./tmux.conf)
      "run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux"
    ];
    terminal = "xterm-256colors";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.net-speed
      tmuxPlugins.mode-indicator
      tmuxPlugins.yank
      tmuxPlugins.sensible
      tmuxPlugins.catppuccin
      tmuxPlugins.cpu
      # tmux-mem-cpu-load
    ];
  };
}
