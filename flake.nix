{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nvimdots = {
      url = "github:TonyWu20/nvimdots/nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
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
    nushell-cfg = {
      url = "github:TonyWu20/nushell_hm_module";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    castep_job_submit.url = "git+ssh://git@github.com/TonyWu20/castep_job_submit";
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
    , castep_job_submit
    , ...
    }:
    let
      system = "x86_64-linux";
      claude-code-rev = "v2.1.138";

      claude-code-overlay = final: prev:
        let
          stdenv = final.stdenvNoCC;
          baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
          platformKey = "${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}";
        in
        {
          claude-code =
            prev.claude-code.overrideAttrs
              (old: rec {
                version = final.lib.removePrefix "v" claude-code-rev;
                src = final.fetchurl {
                  url = "${baseUrl}/${version}/${platformKey}/claude";
                  sha256 = "sha256-dZ0jzmJhk8ibyLNcXGyoqeM7nC5QTuFD5M0RmYh3QJc=";
                };
              });
        };
      pkgs = import nixpkgs {
        stdenv.hostPlatform.system = system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
          cudaCapabilities = [ "6.1" ];
          cudaVersion = "12.9";
        };
        overlays = [
          fenix.overlays.default
          claude-code-overlay
          (final: prev: {
            # Target the specific CUDA set you are using
            cudaPackages_12_9 = prev.cudaPackages_12_9.overrideScope (cfinal: cprev: {
              # Override the cudnn attribute within that scope
              cudnn = cprev.cudnn.overrideAttrs (oldAttrs: {
                version = "9.8.0.87"; # Your desired version
                src = prev.fetchurl {
                  # You must provide the URL and hash for the specific version
                  url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-aarch64/cudnn-linux-aarch64-9.8.0.87_cuda12-archive.tar.xz";
                  hash = "sha256-8D7OP/B9FxnwYhiXOoeXzsG+OHzDF7qrW7EY3JiBmec=";
                };
              });
            });
          })
        ];
      };
      rustToolchain =
        ({ pkgs, ... }: {
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
            inherit inputs;
          };
          modules = [
            rustToolchain
            sops-nix.nixosModules.sops
            # Import the previous configuration.nix we used,
            # so the old configuration file still takes effect
            ./nixos-main/configuration.nix
            ./fcitx5
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
                  inputs.sops-nix.homeManagerModules.sops
                ];
                users.tony = {
                  imports = [
                    ./home/tony.nix
                    ./nixos-main/home_ssh.nix
                    ./nixos-main/home_wayland.nix
                  ];
                };
                users.jerry = {
                  imports = [
                    ./home/jerry.nix
                  ];
                };
                users.qiuyang = {
                  imports = [
                    ./home/qiuyang.nix
                  ];
                };
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs;
                };
              };
            }
          ];
        };
        "nixos-2" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # The `specialArgs` parameter passes the
          # non-default nixpkgs instances to other nix modules
          specialArgs = {
            inherit inputs;
          };
          modules = [
            rustToolchain
            sops-nix.nixosModules.sops
            # Import the previous configuration.nix we used,
            # so the old configuration file still takes effect
            ./nixos-node1/configuration.nix
            ./fcitx5
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
                  inputs.sops-nix.homeManagerModules.sops
                ];
                users.tony = {
                  imports = [
                    ./home/tony-node.nix
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
                users.qiuyang = {
                  imports = [
                    ./home/qiuyang.nix
                  ];
                };
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
        "nixos-3" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            rustToolchain
            sops-nix.nixosModules.sops
            # Import the previous configuration.nix we used,
            # so the old configuration file still takes effect
            ./nixos-node2/configuration.nix
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
                  inputs.sops-nix.homeManagerModules.sops
                ];
                users.tony = {
                  imports = [
                    ./home/tony-node.nix
                  ];
                };
                users.jerry = {
                  imports = [
                    ./home/jerry.nix
                  ];
                };
                users.qiuyang = {
                  imports = [
                    ./home/qiuyang.nix
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
