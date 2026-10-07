{ pkgs, ... }:
{
  # television replaces the jethrokuan/fzf fish plugin as the shell fuzzy
  # finder.  Its fish integration (share/television/completion.fish) binds:
  #   ctrl-t  smart autocompletion (files/dirs channels)
  #   ctrl-r  command history search
  # Standard tab completion for the tv CLI ships in the package at
  # share/fish/vendor_completions.d/tv.fish (== `tv completions fish`).
  programs.television = {
    enable = true;
    enableFishIntegration = true;

    # tools the television channels and previews run
    extraPackages = [
      pkgs.fd
      pkgs.bat
      pkgs.ripgrep
      pkgs.eza
    ];

    settings = {
      # mirror the old fzf defaults
      ui = {
        ui_scale = 100;
        orientation = "landscape"; # preview panel on the right
        input_bar = {
          border_type = "rounded"; # was: --border
        };
        results_panel = {
          border_type = "rounded";
        };
        preview_panel = {
          size = 67; # was: --preview-window right:67%
          border_type = "rounded";
          header = "{}";
          word_wrap = false;
        };
      };

      # in-app key bindings, merged on top of the defaults
      keybindings = {
        # mirrors the old fzf-fish preview-window toggle
        "ctrl-d" = "scroll_preview_half_page_down";
        "ctrl-u" = "scroll_preview_half_page_up";
      };

      # shell integration: route the current prompt command to a channel
      shell_integration = {
        fallback_channel = "files";
        channel_triggers = {
          "dirs" = [
            "cd"
            "ls"
            "eza"
            "mkdir"
            "rmdir"
          ];
          "files" = [
            "cat"
            "less"
            "head"
            "tail"
            "bat"
            "rg"
            "grep"
            "vim"
            "nvim"
            "cp"
            "mv"
            "mdfried"
          ];
          "env" = [
            "set"
            "unset"
          ];
          "rushi-sessions" = [
            "rushi run"
            "rushi-tui"
          ];
        };
        keybindings = {
          "smart_autocomplete" = "ctrl-t"; # was fzf-fish find-file
          "command_history" = "ctrl-r"; # was fzf-fish history
        };
      };
    };

    # A user cable with the same name overrides the built-in channel.
    # These keep the built-in behavior while applying the old fzf
    # source and preview commands.
    channels = {
      files = {
        metadata = {
          name = "files";
          description = "Select files and directories";
          requirements = [
            "fd"
            "bat"
          ];
        };
        source = {
          # was: fzf defaultCommand "fd --type file -HI -E .git"
          command = [
            {
              name = "Default";
              run = "fd -t f -HI -E .git";
            }
            {
              name = "Hidden";
              run = "fd -t f -H";
            }
          ];
        };
        preview = {
          # was: FZF_PREVIEW_FILE_CMD
          command = "bat --style=header,numbers,grid --line-range :300 --color=always '{}'";
          env = {
            BAT_THEME = "Catppuccin Macchiato";
          };
        };
        keybindings = {
          shortcut = "f1";
          f12 = "actions:edit";
          "ctrl-up" = "actions:goto_parent_dir";
        };
        actions = {
          edit = {
            description = "Open the selected entry in the editor";
            command = "\${EDITOR:-nvim} {}";
            shell = "bash";
            mode = "execute";
          };
          goto_parent_dir = {
            description = "Re-open tv in the parent directory";
            command = "tv files ..";
            mode = "execute";
          };
        };
      };

      dirs = {
        metadata = {
          name = "dirs";
          description = "Select directories";
          requirements = [
            "fd"
            "eza"
          ];
        };
        source = {
          command = [
            {
              name = "Default";
              run = "fd -t d";
            }
            {
              name = "Hidden";
              run = "fd -t d --hidden";
            }
          ];
        };
        preview = {
          # was: FZF_PREVIEW_DIR_CMD
          command = "eza -l --git --no-permissions --icons --no-user --level=2 -T '{}'";
        };
        keybindings = {
          shortcut = "f2";
        };
        actions = {
          cd = {
            description = "Open a shell in the selected directory";
            command = "cd {} && $SHELL";
            mode = "execute";
          };
          goto_parent_dir = {
            description = "Re-open tv in the parent directory";
            command = "tv dirs ..";
            mode = "execute";
          };
        };
      };
    };
  };

  # The rushi-sessions channel is written by the rushi kernel home-manager
  # module. Enable it with programs.rushi.enableTelevisionIntegration = true;
  # It lands in programs.television.channels."rushi-sessions" and the
  # home-manager television module serializes it to
  # ~/.config/television/cable/rushi-sessions.toml.
}
