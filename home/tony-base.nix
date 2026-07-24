{ config, ... }: {
  imports = [ ./default.nix ];
  home.username = "tony";
  home.homeDirectory = "/home/tony";
  home.sessionPath = [ "$HOME/.cargo/bin" ];
  home.sessionVariables.SOPS_AGE_KEY_FILE =
    "${config.home.homeDirectory}/nixos-config/sops/age/keys.txt";

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "TonyWu20";
        email = "tony.w21@gmail.com";
      };
      core = {
        quotepath = false;
      };
      extraConfig = {
        safe.directory = [
          "/home/tony/Downloads/gauss_shell"
        ];
      };
    };
  };

  programs.ssh = {
    enableDefaultConfig = false;
    settings.gh = {
      host = "github.com";
      user = "git";
      hostname = "github.com";
      identityFile = config.sops.secrets."tony-ssh/ssh.key".path;
    };
  };

  sops = {
    defaultSopsFile = ../sops/secrets/my_secrets.yaml;
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    age.generateKey = false;
    secrets."tony-ssh/ssh.key" = {
      mode = "0400";
    };
  };
}
