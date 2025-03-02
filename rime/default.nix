{ config, pkgs, lib, home, ... }:
{
  home.file.".local/share/rime-data" = {
    source = ./rime-data-myflypy/share/rime-data;
    recursive = true;
  };
  home.file.".local/share/rime-ls/build" = {
    source = ./rime-data-myflypy/share/rime-data/build;
    recursive = true;
  };
  home.file.".local/share/rime-ls/default.custom.yaml" = {
    source = ./rime-data-myflypy/share/rime-data/default.custom.yaml;
  };
  home.file.".local/share/rime-ls/double_pinyin_flypy.schema.yaml" = {
    source = ./rime-data-myflypy/share/rime-data/double_pinyin_flypy.schema.yaml;
  };
  home.packages = with pkgs; [
    rime-ls
    rime-data
    librime
  ];

}
