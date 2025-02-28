{ config, ... }: {
  wayland.windowManager.hyprland.settings = {
    workspace = [
      "1, monitor: HDMI-A-1"
      "2, monitor: HDMI-A-1"
      "3, monitor: HDMI-A-2"
    ];
    decoration = {
      "rounding" = "10";
      "rounding_power" = 2;
      "active_opacity" = 1.0;
      "inactive_opacity" = 1.0;
      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
    };
    master = {
      new_status = "slave";
      allow_small_split = "true";
      orientation = "right";
      mfact = 0.66;
    };
  };
}
