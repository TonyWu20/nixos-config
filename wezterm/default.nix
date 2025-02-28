{ config, ... }: {
  programs.wezterm = {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
    colorSchemes = {
      catppuccin-macchiato = (builtins.fromTOML (builtins.readFile ./catppuccin-macchiato.toml));
    };
  };

}
