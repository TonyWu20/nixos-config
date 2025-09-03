{ ... }: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1, 2560x1440@100, auto, 2"
    ];
    workspace = [
      "1, monitor: HDMI-A-1"
      "2, monitor: HDMI-A-1"
    ];
  };
}
