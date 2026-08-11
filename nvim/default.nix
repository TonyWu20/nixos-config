{ pkgs, ... }:
{
  programs.neovim = {
    withRuby = false;
    withPython3 = true;
    enable = true;
    defaultEditor = true;
    nvimdots = {
      enable = true;
      setBuildEnv = true;
      withBuildTools = true;
    };
  };
}
