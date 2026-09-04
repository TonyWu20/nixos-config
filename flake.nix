{
  description = "NixOS cluster flake — 4 machines (head node + 3 compute nodes)";

  inputs = {
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
    wait-for-lsp = {
      url = "github:TonyWu20/wait-for-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-config = {
      url = "git+ssh://git@github.com/TonyWu20/pi-config";
      #url = "git+file:///home/tony/programming/pi-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sglang-flake.url = "github:TonyWu20/sglang_flake";
    terminal-browser-flake.url = "github:TonyWu20/terminal-browser-flake";
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
    , wait-for-lsp
    , pi
    , pi-config
    , sglang-flake
    , terminal-browser-flake
    , ...
    }:
    let
      system = "x86_64-linux";

      # ---- Flake-level overlays (used by devShells, packages, and passed to nixosSystem) ----
      claude-code-rev = "v2.1.193";
      claude-code-overlay = final: prev:
        let
          stdenv = final.stdenvNoCC;
          baseUrl = "https://downloads.claude.ai/claude-code-releases";
          platformKey = "${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}";
        in
        {
          claude-code = prev.claude-code.overrideAttrs (old: rec {
            version = final.lib.removePrefix "v" claude-code-rev;
            src = final.fetchurl {
              url = "${baseUrl}/${version}/${platformKey}/claude";
              sha256 = "sha256-yfBNkp8YvZoQHziX8n3k4eDxXr6EANSq8CmD1z3Wax0=";
            };
          });
        };

      overlays = [
        fenix.overlays.default
        claude-code-overlay
        wait-for-lsp.overlays.default
        (import ./overlays/llama-cpp-dflash2.nix)
        #(final: prev: {
        #  python3 = final.python313;
        #  python3Packages = final.python313Packages;
        #})
        (final: prev: {
          wrapNeovimUnstable = prev.wrapNeovimUnstable.override {
            python3 = final.python313;
          };
        })
        sglang-flake.overlays.default
        terminal-browser-flake.overlays.default
      ];

      pkgs = import nixpkgs {
        system = system;
        config.allowUnfree = true;
        inherit overlays;
      };

      # ---- Rust toolchain module (shared by all machines) ----
      rustToolchain = { pkgs, ... }: {
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
      };

      # ---- Shared home-manager modules (used by all home-manager users) ----
      homeSharedModules = [
        nvimdots.homeManagerModules.default
        catppuccin.homeModules.catppuccin
        nushell-cfg.homeManagerModules.default
        sops-nix.homeManagerModules.sops
        pi.homeModules.default
        (pi-config.piModules.homeManager { system = "x86_64-linux"; })
      ];

      # ---- Machine factory: builds a NixOS system from roles + machine-specific config ----
      mkNixosSystem = { configPath, homeImports, hostRoles ? [ ], enableFcitx5 ? true }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules =
            # Shared boilerplate — identical for every machine
            [
              rustToolchain
              sops-nix.nixosModules.sops
              ({ pkgs, ... }: { nixpkgs = { inherit overlays; }; })
              configPath
              catppuccin.nixosModules.catppuccin
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  sharedModules = homeSharedModules;
                  users = homeImports;
                  backupFileExtension = "backup";
                  extraSpecialArgs = { inherit inputs pi-config; };
                };
              }
              sglang-flake.nixosModules.default
            ]
            # Optional fcitx5 IME (not needed on all machines)
            ++ nixpkgs.lib.optional enableFcitx5 ./fcitx5
            # Role modules — visible composition of machine capabilities
            ++ hostRoles;
        };
    in
    {
      packages.x86_64-linux.default = fenix.packages.x86_64-linux.stable.toolchain;
      packages.x86_64-linux.sglang-usage = import ./sglang-metrics/package.nix {
        inherit pkgs;
      };

      devShells.${system} = {
        rs_font = pkgs.mkShell {
          packages = with pkgs; [ stdenv fish ];
          buildInputs = with pkgs; [ fontconfig ];
          nativeBuildInputs = with pkgs; [ pkg-config ];
          shellHook = ''
            exec fish
          '';
        };
      };

      # ---- Machine definitions: roles make intent visible ----
      nixosConfigurations = {
        # Head node: NFS server, SLURM controller, cache, NAT, desktop
        nixos = mkNixosSystem {
          configPath = ./nixos-main/configuration.nix;
          hostRoles = [
            ./roles/head-node.nix
          ];
          homeImports = {
            tony.imports = [ ./home/tony.nix ./nixos-main/home_ssh.nix ./nixos-main/home_wayland.nix ];
            jerry.imports = [ ./home/jerry.nix ];
            qiuyang.imports = [ ./home/qiuyang.nix ];
          };
        };

        # Compute node with DNS + SOCKS proxy
        "nixos-2" = mkNixosSystem {
          configPath = ./nixos-node1/configuration.nix;
          hostRoles = [
            ./roles/compute-node-plus.nix
          ];
          homeImports = {
            tony.imports = [ ./home/tony-node.nix ./nixos-node1/home_ssh.nix ./nixos-node1/home_wayland.nix ];
            jerry.imports = [ ./home/jerry.nix ./nixos-node1/home_ssh.nix ./nixos-node1/home_wayland.nix ];
            qiuyang.imports = [ ./home/qiuyang.nix ];
          };
        };

        # Bare compute node (minimal)
        "nixos-3" = mkNixosSystem {
          configPath = ./nixos-node2/configuration.nix;
          enableFcitx5 = false;
          hostRoles = [
            ./roles/compute-node.nix
          ];
          homeImports = {
            tony.imports = [ ./home/tony-node.nix ];
            jerry.imports = [ ./home/jerry.nix ];
            qiuyang.imports = [ ./home/qiuyang.nix ];
          };
        };

        # RTX PRO 5000 Blackwell compute node (single user)
        "nixos-pro5000" = mkNixosSystem {
          configPath = ./nixos-pro5000/configuration.nix;
          enableFcitx5 = false;
          hostRoles = [
            ./roles/compute-node-pro5000.nix
          ];
          homeImports = {
            tony.imports = [ ./home/tony-node.nix ./nixos-pro5000/home_ssh.nix ];
          };
        };
      };
    };
}
