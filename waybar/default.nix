{ config, home, pkgs, ... }: {
  home.file.".config/waybar/wittr.sh" = {
    source = ./wittr.sh;
    executable = true;
  };
  home.file.".config/waybar/colors.css".source = ./colors.css;
  home.file.".config/waybar/style.css".source = ./style.css;
  home.file.".config/waybar/gpu.sh" = {
    source = ./gpu.sh;
    executable = true;
  };
  programs.waybar = {
    enable = true;
    settings = {
      topBar = {
        output = [ "HDMI-A-1" "HDMI-A-2" ];
        layer = "top";
        position = "top";
        reload_style_on_change = true;
        height = 40;
        width = 2560;
        spacing = 1;
        modules-center = [ "hyprland/window" ];
        modules-right = [ "custom/weather" ];
        "custom/weather" = {
          "interval" = 60;
          "exec" = "${pkgs.bash}/bin/bash ~/.config/waybar/wittr.sh 'Kowloon'";
          "return-type" = "json";
          "format" = "{}";
          "tooltip" = true;
        };
      };
      bottomBar = {
        output = [ "HDMI-A-1" "HDMI-A-2" ];
        layer = "top";
        position = "bottom";
        reload_style_on_change = true;
        height = 40;
        width = 2560;
        spacing = 1;
        modules-left = [
          "hyprland/workspaces"
          "tray"
          "hyprland/mode"
        ];
        modules-right = [
          "hyprland/workspaces"
          "idle_inhibitor"
          "custom/kernel"
          "disk#ssd"
          "temperature"
          "cpu"
          "custom/nv-gpu"
          "memory"
          "network"
          "pulseaudio"
          "clock"
        ];
        "hyprland/workspaces" = {
          "disable-scroll" = false;
          "all-outputs" = true;
          "warp-on-scroll" = false;
          "format" = "{icon}";
          "format-icons" = {
            "1" = "";
            "2" = "";
            #         "3"= "";
            #         "4"= "";
            #         "5"= "";
            "urgent" = "";
            #         "focused"= "";
            #         "default"= ""; 
          };
        };
        "idle_inhibitor" = {
          "format" = "{icon}";
          "format-icons" = {
            "activated" = "";
            "deactivated" = "";
          };
        };
        "tray" = {
          "icon-size" = 13;
          "spacing" = 10;
        };
        "clock" = {
          "interval" = 60;
          "timezone" = "Asia/Hong_Kong";
          "format" = "{:%F %R }";
          "tooltip-format" = "<tt><small>{calendar}</small></tt>";
          "calendar" = {
            "mode" = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "on-click-right" = "mode";
            "format" = {
              "months" = "<span color='#cba6f7'><b>{}</b></span>";
              "days" = "<span color='#cdd6f4'><b>{}</b></span>";
              "weeks" = "<span color='#94e2d5'>W{}</span>";
              "weekdays" = "<span color='#f9e2af'><b>{}</b></span>";
              "today" = "<span color='#f5e0dc'><b><u>{}</u></b></span>";
            };
          };
          "actions" = {
            "on-click-right" = "mode";
            "on-click-forward" = "tz_up";
            "on-click-backward" = "tz_down";
            "on-scroll-up" = "shift_up";
            "on-scroll-down" = "shift_down";
          };
        };
        "cpu" = {
          "interval" = 3;
          "format" = "{usage}% ";
          "on-click" = "foot --app-id htop htop";
        };
        "memory" = {
          "interval" = 3;
          "format" = "{}%  ";
          "on-click" = "foot --app-id htop htop";
          "tooltip-format" = "Used: {used:0.1f}G/{total:0.1f}G. Swap: {swapUsed:0.1f}G/{swapTotal:0.1f}G";
          "states" = {
            "critical" = 80;
          };
        };
        "temperature" = {
          "interval" = 3;
          "hwmon-path" = "/sys/class/hwmon/hwmon1/temp1_input";
          "critical-threshold" = 90;
          "format-critical" = "{temperatureC}°C {icon}";
          "format" = "{temperatureC}°C {icon}";
          "format-icons" = [
            ""
            ""
            ""
          ];
        };
        "disk#ssd" = {
          "interval" = 60;
          "format" = "{path} {free}  ";
          "path" = "/";
          "tooltip" = true;
          "warning" = 80;
          "critical" = 90;
        };
        "network" = {
          "interval" = 60;
          "interface-ethernet" = "enp1s*";
          "interface-wifi" = "wlan0";
          "format-ethernet" = "eth ";
          "format-wifi" = "{essid} ({signalStrength}%)  ";
          "tooltip-format-ethernet" = "{ifname}: {ipaddr}/{cidr} ";
          "tooltip-format-wifi" = "{ifname}: {ipaddr}/{cidr}  ";
          "format-linked" = "(No IP) ";
          "format-disconnected" = "Disconnected ⚠";
        };
        "custom/nv-gpu" = {
          "interval" = 3;
          "exec" = "${pkgs.bash}/bin/bash ~/.config/waybar/gpu.sh";
          "format" = "{}";
        };
        "custom/kernel" = {
          "exec" = "uname -r | sed -E 's/^([0-9]+\\.[0-9]+\\.[0-9]+)-.*-([a-zA-Z0-9]+)/\\1-\\2/'";
          "format" = "{} ";
        };
        "pulseaudio" = {
          "scroll-step" = 2;
          "format" = "{volume}% {icon} {format_source}";
          "format-bluetooth" = "{volume}% {icon} {format_source}";
          "format-bluetooth-muted" = " {icon} {format_source}";
          "format-muted" = " {format_source}";
          "format-source" = "{volume}% ";
          "format-source-muted" = "";
          "format-icons" = {
            "headphone" = " ";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
          };
          "on-click" = "foot --app-id pulsemixer pulsemixer";
        };
      };
    };
  };
}
