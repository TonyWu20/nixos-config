{ ... }: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1, 1920x1080@100, auto, auto"
    ];
    workspace = [
      "1, monitor: HDMI-A-1"
      "2, monitor: HDMI-A-1"
    ];
  };
}

