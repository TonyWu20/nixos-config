{ config, pkgs, ... }:
let
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-small
      ctex
      cleveref
      enumitem
      comment
      mhchem
      ;

  });
in
{
  home. packages = with pkgs; [
    tex
  ];
}
