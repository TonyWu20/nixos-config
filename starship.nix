{ config, pkgs, ... }: {
  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = true;
      right_format = "[](peach)$time[](peach)";
      format = "
[┌──](bold green)$username($style)[─> ](bold green)$nix_shell$rust$git_branch$git_status$cmd_duration
[│](bold green)$directory
[└─](bold green)$character$jobs
";
      aws.disabled = true;
      gcloud.disabled = true;
      username = {
        show_always = true;
        style_user = "bold bg:base fg:text";
        style_root = "bold bg:#458588 fg:#fbf1c7";
        format = "[ $user ]($style)";
      };
      directory = {
        style = "bg:base fg:rosewater bold";
        format = "[$path]($style)";
        truncation_length = 3;
        truncation_symbol = ".../";
      };
      git_branch = {
        symbol = "";
        style = "bg:base fg:red bold";
        format = "(bold mauve)[$symbol $branch ]($style)";
      };
      git_status = {
        style = "bg:base";
        format = "[[($all_status$ahead_behind )](bg:base fg:red)]($style)";
      };
      character = {
        success_symbol = "[>](bold green)[>](bold yellow)[>](bold red)";
        error_symbol = "[✗](bold red)";
        vicmd_symbol = "[V](bold yellow)";
      };
      rust = { format = "[[ $symbol($version) ](bg:base fg:peach italic bold)]($style)"; };
      jobs = {
        disabled = false;
        symbol = "✦";
        format = "[$symbol$number]($style) ";
      };
      time = {
        disabled = false;
        style = "bold bg:peach fg:mantle";
        format = "[ $time]($style)";
      };
    };
  };
}
