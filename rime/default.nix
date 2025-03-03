{ config, pkgs, lib, home, ... }:
{
  # 需要手动 rime_deploy 生成 build 文件夹方能生效?
  home.file.".local/share/rime-data" = {
    source = ./rime-data-myflypy/share/rime-data;
    recursive = true;
  };
  home.file.".local/share/rime-ls" = {
    source = ./rime-data-myflypy/share/rime-data;
    recursive = true;
  };
  home.file.".local/share/fcitx5/rime" = {
    source = ../rime/rime-data-myflypy/share/rime-data;
    recursive = true;
  };
  home.packages =
    let
      # 为了不使用默认的 rime-data，改用我自定义的小鹤音形数据，这里需要 override
      # 参考 https://github.com/NixOS/nixpkgs/blob/e4246ae1e7f78b7087dce9c9da10d28d3725025f/pkgs/tools/inputmethods/fcitx5/fcitx5-rime.nix
      config.packageOverrides = pkgs: {
        rime-ls = pkgs.rime-ls.override {
          rimeDataPkgs = [
            ./rime-data-myflypy/share/rime-data
          ];
        };
      };
    in
    with pkgs; [
      rime-ls
      # rime-data
      librime
    ];

}
