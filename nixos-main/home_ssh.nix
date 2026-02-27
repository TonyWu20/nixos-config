{ config, ... }: {
  programs.ssh = {
    matchBlocks = {
      mac = {
        host = "mac";
        user = "tonywu";
        hostname = "10.147.17.25";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      local-mac = {
        host = "local-mac";
        user = "tonywu";
        hostname = "10.0.0.1";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      cezanne = {
        host = "cezanne";
        user = "handsomechen";
        hostname = "10.147.17.168";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      mba = {
        host = "mba";
        user = "tony";
        hostname = "10.147.17.179";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      node1 = {
        host = "nixos-2";
        user = "tony";
        hostname = "10.0.0.3";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      node1-jerry = {
        host = "nixos-2-jerry";
        user = "jerry";
        hostname = "10.0.0.3";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
        forwardAgent = true;
      };
      node2 = {
        host = "nixos-3";
        user = "tony";
        hostname = "10.0.0.4";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
        forwardAgent = true;
      };
      j = {
        host = "j";
        user = "j";
        hostname = "10.147.17.49";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
      klt = {
        host = "klt";
        user = "Atoms";
        hostname = "172.28.98.21";
        identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
      };
    };
  };
}
