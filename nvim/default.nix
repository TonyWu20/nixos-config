# Neovim is configured by the my-nix-nvim nixvim flake module.
# It is pulled in via homeSharedModules in flake.nix and enables
# programs.nixvim with the editor, plugins, options, and keymaps.
#
# This module used to enable programs.neovim and the myNvim options.
# Those are gone: programs.nixvim and programs.neovim are incompatible,
# and the myNvim options no longer exist.
#
# It is kept as an empty module so the ../nvim import in
# home/default.nix stays valid. Delete this file and that import
# if you prefer a cleaner tree.
{ }
