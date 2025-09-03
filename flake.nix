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
    wezterm.url = "github:wezterm/wezterm?dir=nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nushell-cfg.url = "github:TonyWu20/nushell_hm_module";
  };

  outputs =
    inputs@{ self
    , nvimdots
    , nixpkgs
    , nixpkgs-stable
    , home-manager
    , fenix
    , catppuccin
    , sops-nix
    , nushell-cfg
    , ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system; config = {
        allowUnfree = true;
        cudaSupport = true;
      };
      };
      rustToolchain =
        ({ pkgs, pkgs-stable, ... }: {

          nixpkgs.overlays = [
            fenix.overlays.default
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
            gcc
          ];
        })
      ;
    in
    {
      packages.x86_64-linux.default = fenix.packages.x86_64-linux.stable.toolchain;
      devShells.${system} = {
        rs_font = pkgs.mkShell {
          packages = with pkgs; [
            stdenv
            fish
          ];
          buildInputs = with pkgs; [
            fontconfig
          ];
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          shellHook = ''
            exec fish
          '';
        };
      };
      nixosConfigurations = {
        # Please replace my-nixos with your hostname
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # The `specialArgs` parameter passes the
          # non-default nixpkgs instances to other nix modules
          specialArgs = {
            # To use packages from nixpkgs-stable,
            # we configure some parameters for it first
          };
          modules = [
            rustToolchain
            sops-nix.nixosModules.sops
            # Import the previous configuration.nix we used,
            # so the old configuration file still takes effect
            ./nixos-main/configuration.nix
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
                  nushell-cfg.homeManagerModules.default
                ];
                users.tony = {
                  imports = [
                    ./home/tony.nix
                    ./nixos-main/home_ssh.nix
                    ./nixos-main/home_wayland.nix
                  ];
                };
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
        nixos-2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # The `specialArgs` parameter passes the
          # non-default nixpkgs instances to other nix modules
          modules = [
            rustToolchain
            sops-nix.nixosModules.sops
            # Import the previous configuration.nix we used,
            # so the old configuration file still takes effect
            ./nixos-node1/configuration.nix
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
                  nushell-cfg.homeManagerModules.default
                ];
                users.tony = {
                  imports = [
                    ./home/tony.nix
                    ./nixos-node1/home_ssh.nix
                    ./nixos-node1/home_wayland.nix
                  ];
                };
                users.jerry = {
                  imports = [
                    ./home/jerry.nix
                    ./nixos-node1/home_ssh.nix
                    ./nixos-node1/home_wayland.nix
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
