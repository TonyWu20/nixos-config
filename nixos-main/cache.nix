{ config, ... }: {
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/cache-priv-key.pem";
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      # ... existing hosts config etc. ...
      "10.0.0.2" = {
        locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
      };
    };
  };
}
