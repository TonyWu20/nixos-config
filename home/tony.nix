{ ... }: {
  # basic configuration of git, please change to your own
  imports = [
    ./default.nix
  ];
  home.username = "tony";
  home.homeDirectory = "/home/tony";
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "TonyWu20";
    userEmail = "tony.w21@gmail.com";
    delta = {
      enable = true;
    };
  };
}
