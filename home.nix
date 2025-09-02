{ pkgs, ... }:
{
  imports = [
    ./starship.nix
    ./nvim
    ./hypr
    ./wezterm
    ./tmux
    ./fish
    ./rime
    ./waybar
    ./fcitx5/home.nix
    ./tex
    ./tofi
    ./neomutt
  ];
  # TODO please change the username & home directory to your own
  home.username = "tony";
  home.homeDirectory = "/home/tony";
  home.sessionVariables = {
    EDITOR = "nvim";
    # SLURM_CONF = builtins.getEnv "SLURM_CONF";
  };

  catppuccin = {
    bat = {
      enable = true;
      flavor = "macchiato";
    };

    fzf = {
      enable = true;
      flavor = "macchiato";
    };
    hyprland = {
      enable = true;
      flavor = "macchiato";
    };
    hyprlock = {
      enable = true;
      flavor = "macchiato";
    };
    # tmux = {
    #   enable = true;
    #   flavor = "macchiato";
    # };
    tofi = {
      enable = true;
      flavor = "macchiato";
    };
    skim = {
      enable = true;
      flavor = "macchiato";
    };
    fish = {
      enable = true;
      flavor = "macchiato";
    };
  };
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.wezterm}/bin/wezterm -e ${pkgs.yazi}/bin/yazi";
      };
    };
  };

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
    yazi # terminal file manager
    git-credential-manager
    git-lfs
    gh

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    zoxide
    skim
    nushell
    sad
    delta

    pkg-config

    python3

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

    btop-cuda # replacement of htop/nmon
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

    # texlive later
    alacritty
  ];

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "TonyWu20";
    userEmail = "tony.w21@gmail.com";
    delta = {
      enable = true;
    };
  };


  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.editor = "nvim";
  };

  programs.ssh = {
    enable = true;
    # forwardAgent = true;
    # addKeysToAgent = "yes";
    matchBlocks.gh = {
      host = "github.com";
      user = "git";
      hostname = "github.com";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.mac = {
      host = "mac";
      user = "tonywu";
      hostname = "10.147.17.25";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.local-mac = {
      host = "local-mac";
      user = "tonywu";
      hostname = "10.0.0.1";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.cezanne = {
      host = "cezanne";
      user = "handsomechen";
      hostname = "10.147.17.168";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.klt = {
      host = "klt";
      user = "klt";
      hostname = "10.147.17.146";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.j = {
      host = "j";
      user = "j";
      hostname = "10.0.0.3";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.mba = {
      host = "mba";
      user = "tony";
      hostname = "10.147.17.179";
      identityFile = "~/.ssh/id_ed25519";
    };
    matchBlocks.archDual = {
      host = "archJerry";
      user = "arch";
      hostname = "10.147.17.207";
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  programs.bat =
    {
      enable = true;
    };
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # starship - an customizable prompt for any shell

  programs.bash = {
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
  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
