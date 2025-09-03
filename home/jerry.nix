{ ... }: {
  # basic configuration of git, please change to your own
  imports = [
    ./default.nix
  ];
  home.username = "jerry";
  home.homeDirectory = "/home/jerry";
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
