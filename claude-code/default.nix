{ pkgs, ... }:
{
  home.packages = with pkgs;[
    claude-code-router
  ];
  programs.claude-code = {
    enable = true;
    skills = {
      first-principle = ./first-principles-skill;
      rust-api-doc = ./rust-api-doc;
      humanizer = ./humanizer;
      humanizer-zh = ./humanizer-zh;
    };
  };
}
