# configuration-common.nix — Shared module imports for ALL machines
# This file decomposes the previously monolithic common config into focused modules.
# Machine-specific config lives in each machine's configuration.nix and in roles/.
{ ... }:
{
  imports = [
    ./modules/core.nix
    ./modules/users.nix
    ./modules/gpu.nix
    ./modules/firewall-base.nix
    ./modules/networking/cluster-hosts.nix
    ./sops
    ./slurm
    ./munge
  ];
}
