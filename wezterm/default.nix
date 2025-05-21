{ pkgs, inputs, ... }:
{
  programs.wezterm = {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
    package = inputs.wezterm.packages.${pkgs.system}.default;
  };
}
