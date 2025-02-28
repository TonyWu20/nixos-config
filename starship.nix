{ config, pkgs, ... }: {
  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = true;
      right_format = "[](peach)$time[](peach)";
      format = "
[┌──](bold green)$username($style)[─>](bold green)$rust$git_branch$git_status$cmd_duration
[│](bold green)$directory
[└─](bold green)$character$jobs
";
      aws.disabled = true;
      gcloud.disabled = true;
      palette = "catppuccin_macchiato";
      palettes.catppuccin_macchiato = {
        rosewater = "#f4dbd6";
        flamingo = "#f0c6c6";
        pink = "#f5bde6";
        mauve = "#c6a0f6";
        red = "#ed8796";
        maroon = "#ee99a0";
        peach = "#f5a97f";
        yellow = "#eed49f";
        green = "#a6da95";
        teal = "#8bd5ca";
        sky = "#91d7e3";
        sapphire = "#7dc4e4";
        blue = "#8aadf4";
        lavender = "#b7bdf8";
        text = "#cad3f5";
        subtext1 = "#b8c0e0";
        subtext0 = "#a5adcb";
        overlay2 = "#939ab7";
        overlay1 = "#8087a2";
        overlay0 = "#6e738d";
        surface2 = "#5b6078";
        surface1 = "#494d64";
        surface0 = "#363a4f";
        base = "#24273a";
        mantle = "#1e2030";
        crust = "#181926";
      };
      username = {
        show_always = true;
        style_user = "bold bg:base fg:text";
        style_root = "bold bg:#458588 fg:#fbf1c7";
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
