{ config, pkgs, ... }: {
  programs.tmux = {
    sensibleOnTop = true;
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    extraConfig = builtins.readFile ./tmux.conf;
    terminal = "xterm-256colors";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.net-speed
      tmuxPlugins.mode-indicator
      tmuxPlugins.yank
      tmuxPlugins.sensible
      tmuxPlugins.cpu
      # tmux-mem-cpu-load
      tmuxPlugins.catppuccin
    ];
  };
}
