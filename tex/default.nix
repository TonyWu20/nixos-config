{ pkgs, ... }:
let
  tex = pkgs.texliveSmall.withPackages (ps: with ps; [
    scheme-small
    ctex
    cleveref
    enumitem
    comment
    mhchem
  ]);
in
{
  home. packages = [
    tex
  ];
}
