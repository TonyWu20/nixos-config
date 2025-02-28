{ config, pkgs, ... }: {
  imports = [
    ./bind.nix
    ./general.nix
    ./display.nix
    ./hyprpaper.nix
  ];

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.settings = {
    "$terminal" = "wezterm";
    "$menu" = "tofi-drun";
    "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier
    env = [
      "XCURSOR_SIZE, 24"
      "HYPRCURSOR_SIZE, 24"
    ];
    exec-once = [
      "$terminal"
      "waybar"
      "fcitx5 -r -d"
      "dunst"
      "hyprpaper"
    ];
    input = {
      numlock_by_default = true;
    };
  };

}
