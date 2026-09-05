{ herdr-nix, config, pkgs, lib, ... }:

{
  imports = [
    ./herdr-mirror.nix
    # Derives ~/.config/herdr-mirror/hosts.toml from this machine's
    # programs.ssh.settings (home_ssh.nix per machine), excluding github.
    ./herdr-mirror-hosts.nix
  ];

  herdr = {
    enable = true;
    package = herdr-nix.packages.${pkgs.stdenv.system}.herdr;

    config = {
      onboarding = false;

      terminal = {
        default_shell = "fish";
        shell_mode = "auto";
      };

      theme = {
        name = "catppuccin";
        auto_switch = true;
        light_name = "catppuccin-latte";
        dark_name = "catppuccin";
      };

      keys = {
        # Match tmux C-g prefix (tmux.conf: set -g prefix C-g)
        prefix = "ctrl+g";

        # Tab navigation (tmux: C-h prev window, C-l next window)
        new_tab = "prefix+c";
        next_tab = "prefix+ctrl+l";
        previous_tab = "prefix+ctrl+h";

        # Pane navigation (tmux: h/j/k/l select-pane)
        focus_pane_left = "prefix+h";
        focus_pane_down = "prefix+j";
        focus_pane_up = "prefix+k";
        focus_pane_right = "prefix+l";

        # Splits (tmux: | = side-by-side, - = stacked)
        split_vertical = "prefix+|";
        split_horizontal = "prefix+minus";

        # Reload config (tmux: r source-file)
        reload_config = "prefix+r";

        # Zoom toggle (tmux: u new-window/swap-pane zoom)
        zoom = "prefix+u";

        # Resize. herdr 0.8.0 has no one-key per-direction resize
        # (resize_pane_* only landed in 0.8.2); the only resize path
        # is resize_mode. tmux uses H/J/K/L one-key resize, so bind
        # the resize mode to prefix+R to keep it off the prefix+r
        # reload binding above.
        resize_mode = "prefix+R";

        # Custom commands
        command = [
          {
            key = "prefix+alt+g";
            type = "popup";
            command = "lazygit";
            description = "run lazygit";
            width = "80%";
            height = "80%";
          }

          # herdr-mirror plugin actions. type = "plugin_action" routes the key
          # to an action declared by the mirror plugin (plugin id "mirror");
          # see the herdr-mirror README Keybinds section.
          {
            key = "prefix+shift+m";
            type = "plugin_action";
            command = "mirror.start";
            description = "Mirror: start / resume daemon";
          }
          {
            key = "prefix+shift+s";
            type = "plugin_action";
            command = "mirror.pause";
            description = "Mirror: pause syncing";
          }
          {
            key = "prefix+shift+b";
            type = "plugin_action";
            command = "mirror.restore";
            description = "Mirror: restore closed mirrors";
          }
          {
            key = "prefix+alt+d";
            type = "plugin_action";
            command = "mirror.teardown";
            description = "Mirror: teardown (destructive)";
          }
          {
            key = "prefix+alt+h";
            type = "plugin_action";
            command = "mirror.hide";
            description = "Mirror: hide a host's mirrors";
          }
          {
            key = "prefix+alt+shift+h";
            type = "plugin_action";
            command = "mirror.show";
            description = "Mirror: show hidden mirrors";
          }
          {
            key = "prefix+shift+n";
            type = "plugin_action";
            command = "mirror.new-workspace-pick";
            description = "Mirror: new workspace (pick host)";
          }
          {
            key = "prefix+alt+n";
            type = "plugin_action";
            command = "mirror.remote-new-workspace";
            description = "Mirror: new remote workspace";
          }
          {
            key = "prefix+alt+c";
            type = "plugin_action";
            command = "mirror.remote-new-tab";
            description = "Mirror: new remote tab";
          }
          {
            key = "prefix+alt+v";
            type = "plugin_action";
            command = "mirror.remote-split-right";
            description = "Mirror: split right (remote)";
          }
          {
            key = "prefix+alt+minus";
            type = "plugin_action";
            command = "mirror.remote-split-down";
            description = "Mirror: split down (remote)";
          }
        ];
      };

      ui = {
        pane_borders = true;
        tab_bar_position = "bottom";
        window_title = "{hostname}: {workspace}";
      };

      experimental = {
        kitty_graphics = false;
      };
    };

    extraConfig = "";
  };
}
