{ config, pkgs, inputs, lib, ... }:
let
  fetch_pot = inputs.castep_job_submit.packages.x86_64-linux.default;
  slurm_job = pkgs.writeShellScriptBin "slurm_job.sh" (builtins.readFile ../slurm/slurm_job.sh);
  slurm_lammps = pkgs.writeShellScriptBin "slurm_lammps.sh" (builtins.readFile ../slurm/slurm_lammps.sh);
  catppuccin_programs = [
    "bat"
    "btop"
    "delta"
    "eza"
    "fish"
    "fzf"
    "hyprland"
    "hyprlock"
    "nushell"
    "skim"
    "starship"
    "tofi"
    "tmux"
    "yazi"
  ];

in
{
  imports = [
    ../starship.nix
    ../nvim
    ../wezterm
    ../tmux
    ../fish
    ../fcitx5/home.nix
    ../rime
    ../claude-code
  ];
  # TODO please change the username & home directory to your own
  home.sessionVariables = {
    EDITOR = "nvim";
    # SLURM_CONF = builtins.getEnv "SLURM_CONF";
  };
  home.sessionPath = [
    "$HOME/.cargo/bin/"
  ];


  catppuccin = lib.attrsets.genAttrs catppuccin_programs (prog: { enable = true; flavor = "macchiato"; });
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.wezterm}/bin/wezterm -e ${pkgs.yazi}/bin/yazi";
      };
    };
  };
  # systemd.user.services.munged.unitConfig.After = [ "sops-nix.service" ];

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  # !! Important! Enable numlock
  xsession.numlock.enable = true;
  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them
    bat
    fastfetch
    git-credential-manager
    git-lfs
    gh

    # archives
    zip
    xz
    unzip
    p7zip

    uv
    nodejs_25

    # utils
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    zoxide
    skim
    sad
    delta
    rsync

    pkg-config

    tree-sitter
    (python3.withPackages
      (ps: with ps;[ ps.pynvim huggingface-hub ]))

    # fonts
    fontconfig
    nerd-fonts.hack
    nerd-fonts.symbols-only
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans
    source-han-sans-vf-ttf
    source-han-mono
    noto-fonts
    source-sans
    source-sans-pro

    # Self-packaged CASTEP v25.1.2
    #castep_25_12


    # networking tools
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    simple-http-server

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    imagemagick

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    glow # markdown previewer in terminal
    neomutt # email client in command line
    pandoc

    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb

    # hyprland related
    hyprpaper
    hypridle
    hyprlock
    tofi
    waybar
    wev
    dunst
    jq

    # texlive later
    alacritty
    fetch_pot
    slurm_job
    slurm_lammps
  ];
  programs = {
    btop = {
      enable = true;
      package = (pkgs.btop-cuda.overrideAttrs
        (old: {
          cmakeFlags = old.cmakeFlags ++ [ (lib.cmakeBool "BTOP_GPU" true) ];
        })) # replacement of htop/nmon
      ;
    };

    yazi = {
      enable = true;
      shellWrapperName = "y";
      settings = {
        plugins = {
          prepend_previewers = [{
            mime = "image/tiff";
            run = "magick";
          }
            {
              name = "*.tif";
              run = "magick";
            }];
          prepend_preloaders = [
            { mime = "image/tiff"; run = "magick"; }
          ];
        };
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = true;
      };
    };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings.editor = "nvim";
    };
    ssh = {
      enable = true;
      # forwardAgent = true;
      # addKeysToAgent = "yes";
    };
    bat =
      {
        enable = true;
      };
    fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultOptions = [
        "--height 80%"
        "--reverse"
        "--border"
        "--preview-window right:67%"
      ];
      defaultCommand = "fd --type file -HI -E .git --color=always";
      fileWidgetOptions = [
        "--preview 'bat -n --color=always {}'"
        "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
        "--walker-skip .git,node_modules,target"
      ];
    };
    # starship - an customizable prompt for any shell
    bash = {
      enable = true;
      enableCompletion = true;
      # TODO add your custom bashrc here
      bashrcExtra = ''
        export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      '';

      # set some aliases, feel free to add more or remove some
      # shellAliases = {
      #   k = "kubectl";
      #   urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      #   urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
      # };
    };
    direnv.enable = true;
    direnv.enableNushellIntegration = true;
    direnv.nix-direnv.enable = true;
    # Let home Manager install and manage itself.
    home-manager.enable = true;
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
