{ config, ... }: {

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mainMod, Q, exec, $terminal"
      "$mainMod, C, killactive"
      "$mainMod, M, exit"
      "$mainMod, T, exec, firefox"
      "ALT, SPACE, exec, $menu |xargs hyprctl dispatch exec --"
      "ALT, t, movefocus, l"
      "ALT, r, movefocus, r"
      "ALT, h, movefocus, u"
      "ALT, o, movefocus, d"
      # Workspace switch
      "$mainMod CTRL, KP_END, workspace,1"
      "$mainMod CTRL, KP_DOWN, workspace,2"
      "$mainMod CTRL, KP_NEXT, workspace,3"
      # Move active window to workspace
      "ALT SHIFT, KP_END, movetoworkspace, 1"
      "ALT SHIFT, KP_DOWN, movetoworkspace, 2"
      "ALT SHIFT, KP_NEXT, movetoworkspace, 3"
      # Cycle through workspace
      "$mainMod, J, workspace, e+1"
      "$mainMod, K, workspace, e-1"
      "SUPER CTRL, Q, exec, hyprlock"
      # Swap windows
      "$mainMod SHIFT, T, swapwindow, l"
      "$mainMod SHIFT, R, swapwindow, r"
      "$mainMod SHIFT, H, swapwindow, u"
      "$mainMod SHIFT, O, swapwindow, d"
      "$mainMod SHIFT, L, layoutmsg, swapwithmaster"
      "$mainMod, R, layoutmsg, orientationcycle"
    ];
    windowrulev2 = [
      # Ignore maximize requests from apps.
      "suppressevent maximize, class:.*"
      # Fix some dragging issues with XWayland
      "nofocus, class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
    ];
  };
}
