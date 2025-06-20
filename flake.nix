{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nvimdots = { url = "github:TonyWu20/nvimdots/nix"; };
    catppuccin.url = "github:catppuccin/nix";
    fenix = { url = "github:nix-community/fenix"; inputs.nixpkgs.follows = "nixpkgs"; };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    castep.url = "git+ssh://git@github.com/TonyWu20/CASTEP-25.12-nixos";
    wezterm.url = "github:wezterm/wezterm?dir=nix";
    castep_devShells = { url = "github:TonyWu20/castep_devshell"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ self, nvimdots, nixpkgs, nixpkgs-stable, home-manager, fenix, catppuccin, castep, castep_devShells, ... }: {
    packages.x86_64-linux.default = fenix.packages.x86_64-linux.stable.toolchain;
    devShells = castep_devShells.devShells;
    nixosConfigurations = {
      # Please replace my-nixos with your hostname
      nixos = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        # The `specialArgs` parameter passes the
        # non-default nixpkgs instances to other nix modules
        specialArgs = {
          # To use packages from nixpkgs-stable,
          # we configure some parameters for it first
          pkgs-stable = import nixpkgs-stable {
            # Refer to the `system` parameter from
            # the outer scope recursively
            inherit system;
            config.allowUnfree = true;
          };
        };
        modules = [
          ({ pkgs, pkgs-stable, ... }: {

            nixpkgs.overlays = [
              fenix.overlays.default
              castep.overlays.default
              (self: super: {
                # wezterm = pkgs-stable.wezterm;
                # hyprland = pkgs-stable.hyprland;
              })
            ];
            nix.registry = {
              myShell.flake = self;
            };
            environment.systemPackages = with pkgs; [
              (fenix.packages.x86_64-linux.stable.withComponents [
                "cargo"
                "clippy"
                "rust-src"
                "rustc"
                "rustfmt"
                "rust-analyzer"
              ])
              gcc
            ];
          })
          # Import the previous configuration.nix we used,
          # so the old configuration file still takes effect
          ./configuration.nix
          ./fcitx5
          # catppuccin/nix
          catppuccin.nixosModules.catppuccin
          # make home-manager as a module of nixos
          # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                nvimdots.homeManagerModules.default
                catppuccin.homeModules.catppuccin
              ];
              users.tony = {
                imports = [
                  ./home.nix
                  ./nvim/nvimdots.nix
                  # catppuccin.homeManagerModules.catppuccin
                ];
              };
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
            };

          }
        ];
      };
    };
  };
}
