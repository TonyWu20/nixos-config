# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./sops
      ./slurm
      ./munge
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.graphics = {
    enable = true;
  };
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;

    # Enable the Nvidia settings menu
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "570.86.16"; # use new 570 drivers
      sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
      openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
      settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
      usePersistenced = false;
    };
  };

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Hong_Kong";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];

  };
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };


  # Enable the X11 windowing system.
  # services.xserver.enable = true;




  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tony = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqIz6gNydwx4jPWhusIUBHY0eWG92uVsl4zHsGdOCHG tony.w21@gmail.com= tony"
    ];
    shell = pkgs.fish;
  };

  programs.firefox.enable = true;
  programs.hyprland.enable = true;
  programs.fish.enable = true;
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    terminal = "xterm-256colors";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.net-speed
      tmuxPlugins.mode-indicator
      tmuxPlugins.yank
      tmuxPlugins.sensible
      # tmux-mem-cpu-load
    ];
    # extraConfig = "set -g @catppuccin-flavor macchiato";

  };

  # environment.variables = {
  #   LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
  #     fontconfig
  #   ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    udisks2
    usbutils
    udiskie
    linuxKernel.kernels.linux_6_12
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    # fish
    fish
    fishPlugins.fzf-fish
    fishPlugins.z
    fishPlugins.done
    fishPlugins.forgit
    ripgrep
    fd
    skim
    greetd
    zerotierone
    wezterm
    hyprland
    tmux
    wl-clipboard-rs
    bat
    pkg-config
    fontconfig
    slurm
    sops
    age
  ];
  environment.variables.EDITOR = "nvim";
  environment.sessionVariables.SOPS_AGE_KEY_FILE = "/home/tony/nixos-config/sops/age/keys.txt";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  programs.ssh.startAgent = true;
  services.openssh = {
    enable = true;
  };

  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ "b15644912e4d3047" ];
  services.gvfs.enable = true;
  services.devmon.enable = true;
  services.udisks2.enable = true;
  # services.rustdesk-server = { enable = true; };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };
  systemd.services.numLockOnTty = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      # /run/current-system/sw/bin/setleds -D +num < "$tty";
      ExecStart = lib.mkForce (pkgs.writeShellScript "numLockOnTty" ''
        	      for tty in /dev/tty{1..6}; do
        		  ${pkgs.kbd}/bin/setleds -D +num < "$tty";
        	      done
        	    '');
    };
  };
  # Open ports in the firewall.
  networking.interfaces.enp6s0.ipv4.addresses = [{
    address = "10.0.0.2";
    prefixLength = 24;
  }];
  networking.extraHosts = ''
    10.0.0.2 nixos
    10.0.0.3 j-ubuntu
  '';
  fileSystems = {
    "/export/castep_jobs" = {
      device = "/home/tony/Downloads/castep_jobs";
      options = [ "bind" ];
      fsType = "nfs";
    };
    "/export/CASTEP-6.11-nixos" = {
      device = "/home/tony/Downloads/CASTEP-6.11-nixos";
      options = [ "bind" ];
      fsType = "nfs";
    };
    "/export/CASTEP-25.12-nixos" = {
      device = "/home/tony/Downloads/CASTEP-25.12-nixos";
      options = [ "bind" ];
      fsType = "nfs";
    };
    "/export/castep_devshell" = {
      device = "/home/tony/Downloads/castep_devshell";
      options = [ "bind" ];
      fsType = "nfs";
    };
  };
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS
  services.nfs.server = {
    enable = true;
    exports = ''
      /export       10.0.0.2(rw,fsid=0,no_subtree_check) 10.0.0.3(rw,fsid=0,no_subtree_check)
      /export/castep_jobs     *(rw,nohide,insecure,no_subtree_check)
      /export/CASTEP-25.12-nixos     *(rw,nohide,insecure,no_subtree_check)
      /export/castep_devshell     *(rw,nohide,insecure,no_subtree_check)
    '';
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
  };
  networking.firewall = {
    enable = true;
    # for NFSv3; view with `rpcinfo -p`
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 22 3000 8000 8080 10000 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14";
  };

  # Optimize storage
  # You can also manually optimize the store via:
  #    nix-store --optimise
  # Refer to the following link for more details:
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;
  nix.settings.trusted-users = [ "root" "tony" ];
  console = {
    earlySetup = true;
    packages = with pkgs; [ terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };
}

