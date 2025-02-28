{ config, ... }: {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "./azukisan_2025Feb.jpeg"
      ];
      wallpaper = [
        "./azukisan_2025Feb.jpeg"
      ];

    };
  };
}
