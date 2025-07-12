{ pkgs, ... }:
{
  programs.nushell = {
    enable = true;
    plugins = with pkgs; [
      nushellPlugins.skim
      nushellPlugins.polars
      nushellPlugins.polars
      nushellPlugins.highlight
      nushellPlugins.gstat
    ];
    envFile.source = ./env.nu;
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./bib_management.nu)
      (builtins.readFile ./crossref.nu)
      (builtins.readFile ./keybindings.nu)
      ''
        let carapace_completer = {|spans| 
          carapace $spans.0 nushell ...$spans | from json
        }
        $env.config.completions.external.enable=true
        $env.config.completions.external.max_results=100
        $env.config.completions.external.completer=$carapace_completer
      ''
    ];
    settings = {
      table = {
        header_on_separator = false;
        abbreviated_row_count = null;
        footer_inheritance = true;
        trim = {
          methodology = "wrapping";
          wrapping_try_keep_words = true;
        };
      };
      datetime_format = {
        table = null;
        normal = "%m/%d/%y %I:%M:%S%p";
      };
      filesize.unit = "metric";
      render_right_prompt_on_last_line = false;
      float_precision = 16;
      ls.use_ls_colors = true;
      cursor_shape.emacs = "inherit"; # Cursor shape in emacs mode
      cursor_shape.vi_insert = "block"; # Cursor shape in vi-insert mode
      cursor_shape.vi_normal = "underscore"; # Cursor shape in normal vi mode
      edit_mode = "vi";
      buffer_editor = "nvim";
      history = {
        file_format = "sqlite";
        max_size = 5000000;
        sync_on_enter = false;
      };
      shell_integration = {
        osc2 = true;
        osc7 = true;
        osc9_9 = false;
        osc8 = true;
      };
      error_style = "fancy";
      display_errors.termination_signal = true;
    };
  };
  programs = {
    zoxide.enableNushellIntegration = true;
    starship.enableNushellIntegration = true;
    eza.enableNushellIntegration = true;
    carapace = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
  catppuccin.nushell = {
    enable = true;
    flavor = "macchiato";
  };

}
