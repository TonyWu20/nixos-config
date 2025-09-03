{ ... }: {
  programs.ssh = {
    # matchBlocks.gh = {
    #   host = "github.com";
    #   user = "git";
    #   hostname = "github.com";
    #   identityFile = "~/.ssh/id_ed25519";
    # };
    matchBlocks.local-mac = {
      host = "local-mac";
      user = "tonywu";
      hostname = "10.0.0.1";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.cezanne = {
      host = "cezanne";
      user = "handsomechen";
      hostname = "10.147.17.168";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.master = {
      host = "master";
      user = "tony";
      hostname = "10.0.0.2";
      identityFile = "~/.ssh/id_ed25519";
    };
  };
}
