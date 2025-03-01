{ config, pkgs, lib, ... }:
{
  config.home.packages = with pkgs; [
    rime-ls
    rime-data
    librime
  ];

}
