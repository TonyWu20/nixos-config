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
      "fcitx5 -r -d"
      "dunst"
      "hyprpaper"
      "waybar"
    ];
    input = {
      numlock_by_default = true;
    };
    xwayland = {
      force_zero_scaling = true;
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "800, 60";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "<span foreground=\"##cad3f5\">Password...</span>";
          shadow_passes = 2;
        }
      ];
    };
  };

}

