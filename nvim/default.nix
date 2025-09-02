{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    nvimdots = {
      enable = true;
      setBuildEnv = true;
      withBuildTools = true;
    };
    # enable = true;
    # extraPackages = with pkgs; [
    #   go
    #   python3
    # ];
  };
}
