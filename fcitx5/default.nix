{ config, pkgs, ... }: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons =
        let
          # 为了不使用默认的 rime-data，改用我自定义的小鹤音形数据，这里需要 override
          # 参考 https://github.com/NixOS/nixpkgs/blob/e4246ae1e7f78b7087dce9c9da10d28d3725025f/pkgs/tools/inputmethods/fcitx5/fcitx5-rime.nix
          config.packageOverrides = pkgs: {
            fcitx5-rime = pkgs.fcitx5-rime.override {
              rimeDataPkgs = [
                ../rime/rime-data-myflypy
              ];
            };
          };
        in
        with pkgs; [
          fcitx5-chinese-addons
          fcitx5-rime
          catppuccin-fcitx5
        ];
      waylandFrontend = true;
      settings = {
        addons = {
          classicui.globalSection = {
            Font = "Noto Sans CJK SC 24";
            MenuFont = "Noto Sans 24";
            TrayFont = "Noto Sans Bold 18";
            Theme = "catppuccin-macchiato-maroon";
            DarkTheme = "catppuccin-macchiato-maroon";
          };
        };
        globalOptions = { "Hotkey/TriggerKeys" = { "0" = "Control+space"; }; };
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "rime";
          GroupOrder."0" = "Default";
        };
      };
    };
  };
}
