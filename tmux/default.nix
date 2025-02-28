{ config, pkgs, ... }: {
  programs.tmux = {
    sensibleOnTop = true;
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    keyMode = "vi";
    extraConfig = builtins.readFile ./tmux.conf;
  };
}
