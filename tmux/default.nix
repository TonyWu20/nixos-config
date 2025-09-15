{ config, pkgs, ... }: {
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

        source "${pkgs.tmuxPlugins.catppuccin}/utils/status_module.conf"
      ''
      (builtins.readFile ./tmux_catppuccin.conf)
      "run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux"
    ];
    terminal = "xterm-256color";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.net-speed
      tmuxPlugins.mode-indicator
      tmuxPlugins.yank
      tmuxPlugins.sensible
      tmuxPlugins.catppuccin
      tmuxPlugins.cpu
    ];
  };
}
