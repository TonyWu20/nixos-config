{config,pkgs,...}: {
programs.neovim = {
  enable = true;
  defaultEditor = true;
  # nvimdots = {
  # enable = true;
  #   setBuildEnv = true;  # Only needed for NixOS
  #   withBuildTools = true; # Only needed for NixOS
  # };
};
}
