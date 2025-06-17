{ config, pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = "
    fish_vi_key_bindings
    zoxide init fish | source
    set -gx FZF_DEFAULT_OPTS --height 80% --reverse --border --preview-window right:67%
    set -gx FZF_DEFAULT_COMMAND 'fd --type file -HI -E .git --color=always'
    set -gx FZF_PREVIEW_FILE_CMD 'bat --style=header,numbers,grid --line-range :300 --color=always'
    set -gx FZF_PREVIEW_DIR_CMD 'eza -l --git --no-permissions --icons --no-user --level=2 -T '
    set -gx FZF_CTRL_T_OPTS '--walker-skip .git,node_modules,target --preview \"bat -n --color=always {}\" --bind \"ctrl-/:change-preview-window(down|hidden|)\"'
    set -U FZF_TMUX 0
    set -U FZF_COMPLETE 1
    set -ga PATH ~/.cargo/bin/
    ";
    shellAbbrs = {
      vim = "nvim";
    };
    functions = {
      num_kpt_geom = {
        argumentNames = [ "cell" ];
        body = "sed 's/\r$//g' $cell | rg -UP \"(?s)(?<=%BLOCK KPOINTS_LIST\n).*(?=%ENDBLOCK KPOINTS_LIST)\"  |wc -l";
        description =
          "Count the lines inside block KPOINTS_LIST to get the number of kpoints in non-spectral task cell.
# Args:
- cell: path to the cell that contains block KPOINTS_LIST.";
      };
      num_kpt_spec = {
        argumentNames = [ "cell" ];
        body = "sed 's/\r$//g' $cell | rg -UP \"(?s)(?<=%BLOCK SPECTRAL_KPOINT_LIST\n).*(?=%ENDBLOCK SPECTRAL_KPOINT_LIST)\"  |wc -l";
        description =
          "Count the lines inside block SPECTRAL_KPOINT_LIST to get the number of kpoints in spectral task cell.
# Args:
- cell: path to the cell that contains block SPECTRAL_KPOINT_LIST.";
      };
    };
  };
  home.packages = with pkgs; [
    fishPlugins.z
    fishPlugins.fzf
    fishPlugins.done
    fishPlugins.bass
    fishPlugins.forgit
  ];
}

