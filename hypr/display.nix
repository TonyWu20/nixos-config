{ config, ... }: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1, preferred, auto, auto,"
      "HDMI-A-2, 1920x1080@100, auto, auto"
    ];
    workspace = [
      "1, monitor: HDMI-A-1"
      "2, monitor: HDMI-A-1"
      "3, monitor: HDMI-A-2"
    ];
    animations = {
      enabled = false;
    };
    decoration = {
      "rounding" = "10";
      "rounding_power" = 2;
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
