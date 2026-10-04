# mdfried — Catppuccin Macchiato colorscheme
#
# Writes ~/.config/mdfried/config.toml via home-manager.
# Colors follow the Catppuccin Macchiato palette.
#
# If a catppuccin/nix mdfried port is ever merged upstream, you
# can replace this with:
#   catppuccin.mdfried.enable = true;
#   catppuccin.mdfried.flavor = "macchiato";
# and delete this module.
{ ... }:

{
  home.file.".config/mdfried/config.toml".source = ./config.toml;
}
