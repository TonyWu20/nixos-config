{ config, pkgs, ... }: {
  programs.fish = {
    enable = true;
    shellInit = "
    fish_vi_key_bindings
    zoxide init fish | source
    ";
    shellAbbrs = {
      vim = "nvim";
    };
  };
  home.packages = with pkgs; [
    fishPlugins.z
    fishPlugins.fzf
    fishPlugins.done
  ];
}
