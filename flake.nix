{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nvimdots = { url = "github:TonyWu20/nvimdots/nix"; inputs.nixpkgs.follows = "nixpkgs"; };
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
    castep.url = "git+file:///home/tony/Downloads/CASTEP-25.12-nixos";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, home-manager, fenix, catppuccin, castep, ... }: {
    packages.x86_64-linux.default = fenix.packages.x86_64-linux.stable.toolchain;
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
                wezterm = pkgs-stable.wezterm;
              })
            ];
            environment.systemPackages = with pkgs; [
              (fenix.packages.x86_64-linux.stable.withComponents [
                "cargo"
                "clippy"
                "rust-src"
                "rustc"
                "rustfmt"
                "rust-analyzer"
              ])
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [
              inputs.nvimdots.homeManagerModules.nvimdots
              catppuccin.homeManagerModules.catppuccin
            ];

            home-manager.users.tony = {
              imports = [
                ./home.nix
                ./nvim/nvimdots.nix
                # catppuccin.homeManagerModules.catppuccin
              ];
            };
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = inputs;

          }
        ];
      };
    };
  };
}
