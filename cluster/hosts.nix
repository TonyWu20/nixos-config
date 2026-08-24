{ ... }: {
  networking.hosts = {
    "10.0.0.6" = [ "nixos-pro5000" ];
    "10.0.0.4" = [ "nixos-3" ];
    "10.0.0.3" = [ "nixos-2" ];
    "10.0.0.2" = [ "nixos" ];
  };
}
