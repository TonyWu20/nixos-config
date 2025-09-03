{ config, ... }: {
  wayland.windowManager.hyprland.settings = {
    animations = {
      enabled = false;
    };
    decoration = {
      "rounding" = "10";
      # "rounding_power" = 2;
      "active_opacity" = 1.0;
      "inactive_opacity" = 1.0;
      shadow = {
        enabled = false;
        # range = 4;
        # render_power = 3;
        # color = "rgba(1a1a1aee)";
      };
    };
    master = {
      new_status = "slave";
      allow_small_split = "true";
      orientation = "right";
      mfact = "0.6666666";
    };
  };
}
