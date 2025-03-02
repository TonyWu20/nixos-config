{ config, home, ... }: {
  home.file.".config/hypr/azukisan_2025Feb.jpeg".source = ./azukisan_2025Feb.jpeg;
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "~/.config/hypr/azukisan_2025Feb.jpeg"
      ];
      wallpaper = [
        ", ~/.config/hypr/azukisan_2025Feb.jpeg"
      ];

    };
  };
}
