{ config, ... }: {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/tony/nixos-config/hypr/azukisan_2025Feb.jpeg"
      ];
      wallpaper = [
        "/home/tony/nixos-config/hypr/azukisan_2025Feb.jpeg"
      ];

    };
  };
}
