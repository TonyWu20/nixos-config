{ config, pkgs, ... }: {
  programs.fish = {
    enable = true;
    shellInit = "
    fish_vi_key_bindings
    zoxide init fish | source
    set -gx FZF_DEFAULT_OPTS --height 80% --reverse --border --preview-window right:67%
    set -gx FZF_DEFAULT_COMMAND 'fd --type file -HI -E .git --color=always'
    set -gx FZF_PREVIEW_FILE_CMD 'bat --style=header,numbers,grid --line-range :300 --color=always {}'
    set -gx FZF_PREVIEW_DIR_CMD 'eza -l --git --no-permissions --icons --no-user --level=2 -T '
    set -gx FZF_CTRL_T_OPTS '--walker-skip .git,node_modules,target --preview \"bat -n --color=always {}\" --bind \"ctrl-/:change-preview-window(down|hidden|)\"'
    set -U FZF_TMUX 1
    ";
    shellAbbrs = {
      vim = "nvim";
    };
  };
  home.packages = with pkgs; [
    fishPlugins.z
    fishPlugins.fzf
    fishPlugins.done
    fishPlugins.bass
    fishPlugins.fifc
  ];
}
