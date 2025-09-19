{ config, ... }: {
  programs.ssh = {
    matchBlocks.local-mac = {
      host = "local-mac";
      user = "tonywu";
      hostname = "10.0.0.1";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
    matchBlocks.cezanne = {
      host = "cezanne";
      user = "handsomechen";
      hostname = "10.147.17.168";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
    matchBlocks.master = {
      host = "master";
      user = "tony";
      hostname = "10.0.0.2";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
  };
}
