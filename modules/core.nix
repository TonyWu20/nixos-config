# modules/core.nix — Cluster-wide settings shared by ALL machines
{ config, lib, pkgs, options, inputs, ... }:

{
  imports = [
    ../sops
    ../slurm
    ../munge
  ];

  # ---- nixpkgs config (CUDA, unfree) ----
  nixpkgs = {
    config = {
      allowUnfree = true;
      cudaSupport = true;
      cudaCapabilities = [ "6.1" ];
      cudaVersion = "12.9";
    };
    overlays = [
      inputs.fenix.overlays.default
      (final: prev: {
        cudaPackages_12_9 = prev.cudaPackages_12_9.overrideScope (cfinal: cprev: {
          cudnn = cprev.cudnn.overrideAttrs (oldAttrs: rec {
            version = "9.11.1.4";
            src = prev.fetchurl {
              url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-${version}_cuda12-archive.tar.xz";
              hash = "sha256-YJrEikSORTMoek18YgVr8TD66MOx6yohgIDingAm7Bg=";
            };
          });
        });
      })
    ];
  };

  # ---- Boot ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.supportedFilesystems = [ "nfs" ];

  # ---- NVIDIA GPU ----
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.142";
      sha256_64bit = "sha256-IJFfzz/+icNVDPk7YKBKKFRTFQ2S4kaOGRGkNiBEdWM=";
      openSha256 = "sha256-BnrIlj5AvXTfqg/qcBt2OS9bTDDZd3uhf5jqOtTMTQM=";
      settingsSha256 = "sha256-BnrIlj5AvXTfqg/qcBt2OS9bTDDZd3uhf5jqOtTMTQM=";
      usePersistenced = false;
    };
  };

  # ---- Nix settings ----
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "tony" "jerry" "qiuyang" ];
      extra-substituters = [
        "https://pi.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # ---- Locale & time ----
  time.timeZone = "Asia/Hong_Kong";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];
  };

  # ---- Networking ----
  networking.networkmanager.enable = true;
  programs.ssh.startAgent = true;
  services.openssh.enable = true;
  services.zerotierone.enable = true;

  # ---- Shell & terminal ----
  programs.fish.enable = true;
  programs.fzf.fuzzyCompletion = true;
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    terminal = "xterm-256colors";
    plugins = with pkgs; [
      tmuxPlugins.resurrect tmuxPlugins.net-speed
      tmuxPlugins.mode-indicator tmuxPlugins.yank tmuxPlugins.sensible
    ];
  };

  # ---- Editor ----
  programs.neovim = { enable = true; withPython3 = true; withRuby = false; };

  # ---- AppImage ----
  programs.appimage = { enable = true; binfmt = true; };

  # ---- Nix LD ----
  programs.nix-ld = {
    enable = true;
    libraries = options.programs.nix-ld.libraries.default ++ (with pkgs; [
      dbus fontconfig freetype glib libGL libxkbcommon libX11 wayland
    ]);
  };

  # ---- Audio ----
  services.pipewire = { enable = true; pulse.enable = true; };

  # ---- Input ----
  services.libinput.enable = true;

  # ---- Storage ----
  services.gvfs.enable = true;
  services.devmon.enable = true;
  services.udisks2.enable = true;

  # ---- NFS ----
  services.rpcbind.enable = true;

  # ---- Console ----
  console = {
    earlySetup = true;
    packages = with pkgs; [ terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };

  # ---- NumLock ----
  systemd.services.numLockOnTty = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.mkForce (pkgs.writeShellScript "numLockOnTty" ''
        for tty in /dev/tty{1..6}; do
          ${pkgs.kbd}/bin/setleds -D +num < "$tty";
        done
      '');
    };
  };

  # ---- Firewall (cluster base: SSH + NFS) ----
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 22 ];
    allowedTCPPortRanges = [{ from = 3000; to = 4000; }];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 22 ];
    allowedUDPPortRanges = [{ from = 60000; to = 65535; }];
  };

  # ---- System packages (all machines) ----
  environment.systemPackages = with pkgs; [
    mosh gcc udisks2 usbutils udiskie
    linuxKernel.kernels.linux_6_12 wget
    fish fishPlugins.fzf-fish fishPlugins.z fishPlugins.done fishPlugins.forgit
    ripgrep fd sops age
  ];
  environment.variables.EDITOR = "nvim";
}
