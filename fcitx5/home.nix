{ config, pkgs, ... }: {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons =
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
  };
}
