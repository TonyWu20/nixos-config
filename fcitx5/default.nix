{ config, pkgs, ... }: {
  inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-rime
        catppuccin-fcitx5
      ];
      waylandFrontend = true;
      settings = {
        addons = {
          classicui.globalSection.Theme = "catppuccin-macchiato-maroon";
          classicui.globalSection.DarkTheme = "catppuccin-macchiato-maroon";
        };
        globalOptions = { "Hotkey/TriggerKeys" = { "0" = "Control+space"; }; };
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "Rime";
          GroupOrder."0" = "Default";
        };
      };
    };
  };
}
