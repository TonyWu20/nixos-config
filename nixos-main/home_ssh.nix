{ config, ... }: {
  programs.ssh = {
    matchBlocks.mac = {
      host = "mac";
      user = "tonywu";
      hostname = "10.147.17.25";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
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
    matchBlocks.mba = {
      host = "mba";
      user = "tony";
      hostname = "10.147.17.179";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
    matchBlocks.node1 = {
      host = "nixos-2";
      user = "tony";
      hostname = "10.0.0.3";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
    matchBlocks.node1-jerry = {
      host = "nixos-2-jerry";
      user = "jerry";
      hostname = "10.0.0.3";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      forwardAgent = true;
    };
    matchBlocks.j = {
      host = "j";
      user = "j";
      hostname = "10.147.17.49";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
  };
}
