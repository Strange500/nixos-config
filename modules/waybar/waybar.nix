{
  pkgs,
  lib,
  host,
  config,
  ...
}:

let
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
  clock24h = true;
in
with lib;
{
  # Configure & Theme Waybar
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = [

      {
            layer = "top";
           "margin-top" = 0;
           "margin-bottom" = 0;
           "margin-left" = 0;
           "margin-right" = 0;
           spacing = 0;

           "modules-left" = [
             "custom/appmenu"
             "group/links"
             "group/settings"
             "group/quicklinks"
             "hyprland/window"
             "custom/empty"
           ];
           "modules-center" = [
             "hyprland/workspaces"
           ];
           "modules-right" = [
             "custom/updates"
             "pulseaudio"
             "bluetooth"
             "battery"
             "network"
             "group/hardware"
             "group/tools"
             "tray"
             "custom/exit"
             "clock"
           ];
         "hyprland/workspaces" = {
            "on-scroll-up" = "hyprctl dispatch workspace r-1";
            "on-scroll-down" = "hyprctl dispatch workspace r+1";
            "on-click" = "activate";
            "active-only" = false;
            "all-outputs" = true;
            format = "{}";
            "format-icons" = {
              urgent = "";
              active = "";
              default = "";
            };
            "persistent-workspaces" = {
              "*" = 5;
            };
          };
          "wlr/taskbar" = {
            format = "{icon}";
            "icon-size" = 18;
            "tooltip-format" = "{title}";
            "on-click" = "activate";
            "on-click-middle" = "close";
            "ignore-list" = [
              "Alacritty"
              "kitty"
            ];
            "app_ids-mapping" = {
              firefoxdeveloperedition = "firefox-developer-edition";
            };
            rewrite = {
              "Firefox Web Browser" = "Firefox";
              "Foot Server" = "Terminal";
            };
          };
          "hyprland/window" = {
            rewrite = {
              "(.*) - Brave" = "$1";
              "(.*) - Chromium" = "$1";
              "(.*) - Brave Search" = "$1";
              "(.*) - Outlook" = "$1";
              "(.*) Microsoft Teams" = "$1";
            };
            "separate-outputs" = true;
          };

          "custom/empty" = {
            format = "";
          };
          "custom/tools" = {
            format = "\uf5fd";
            "tooltip-format" = "Tools";
          };
          "custom/cliphist" = {
            format = "\uf0ea";
            "on-click" = "sleep 0.1 && ~/.config/ml4w/scripts/cliphist.sh";
            "on-click-right" = "sleep 0.1 && ~/.config/ml4w/scripts/cliphist.sh d";
            "on-click-middle" = "sleep 0.1 && ~/.config/ml4w/scripts/cliphist.sh w";
            "tooltip-format" = "Clipboard Manager";
          };
          "custom/updates" = {
            format = "\uf0ab  {}";
            escape = true;
            "return-type" = "json";
            #exec = "~/.config/ml4w/scripts/updates.sh";
            interval = 1800;
            #"on-click" = "$(cat ~/.config/ml4w/settings/terminal.sh) --class dotfiles-floating -e ~/.config/ml4w/scripts/installupdates.sh";
            #"on-click-right" = "~/.config/ml4w/settings/software.sh";
          };
          "custom/wallpaper" = {
            format = "\uf03e";
            "on-click" = "waypaper";
            #"on-click-right" = "~/.config/hypr/scripts/wallpaper-effects.sh";
            "tooltip-format" = "Left: Select a wallpaper\nRight: Select wallpaper effect";
          };
          "custom/waybarthemes" = {
            format = "\uf141";
            #"on-click" = "~/.config/waybar/themeswitcher.sh";
            "tooltip-format" = "Select a waybar theme";
          };
          "custom/settings" = {
            format = "\uf013";
            #"on-click" = "com.ml4w.dotfilessettings";
            "tooltip-format" = "ML4W Dotfiles Settings";
          };
          "custom/keybindings" = {
            format = "\uf11c";
            #"on-click" = "~/.config/hypr/scripts/keybindings.sh";
            tooltip = false;
          };
          "custom/chatgpt" = {
            format = " ";
            #"on-click" = "~/.config/ml4w/settings/ai.sh";
            "tooltip-format" = "AI Support";
          };
          "custom/calculator" = {
            format = "\uf1ec";
            "on-click" = "qalculate-gtk";
            "tooltip-format" = "Open calculator";
          };
          "custom/windowsvm" = {
            format = "\uf17a";
            #"on-click" = "~/.config/ml4w/scripts/launchvm.sh";
            tooltip = false;
          };
          "custom/appmenu" = {
            format = "Apps";
            "on-click" = "sleep 0.2;pkill rofi || rofi -show drun -replace";
            #"on-click-right" = "~/.config/hypr/scripts/keybindings.sh";
            "tooltip-format" = "Left: Open the application launcher\nRight: Show all keybindings";
          };
          "custom/appmenuicon" = {
            format = "\uf303";
            "on-click" = "sleep 0.2;rofi -show drun -replace";
            #"on-click-right" = "~/.config/hypr/scripts/keybindings.sh";
            "tooltip-format" = "Left: Open the application launcher\nRight: Show all keybindings";
          };
          "custom/exit" = {
            format = "\uf011";
            "on-click" = "wlogout";
            "tooltip-format" = "Power Menu";
          };
          "custom/hyprshade" = {
            format = "\ue4dc";
            "tooltip-format" = "Toggle Screen Shader";
            #"on-click" = "sleep 0.5; ~/.config/hypr/scripts/hyprshade.sh";
            #"on-click-right" = "sleep 0.5; ~/.config/hypr/scripts/hyprshade.sh rofi";
          };
          "custom/hypridle" = {
            format = "\uf023";
            "return-type" = "json";
            escape = true;
            "exec-on-event" = true;
            interval = 60;
            #exec = "~/.config/hypr/scripts/hypridle.sh status";
            #"on-click" = "~/.config/hypr/scripts/hypridle.sh toggle";
            #"on-click-right" = "hyprlock";
          };
          "keyboard-state" = {
            numlock = true;
            capslock = true;
            format = "{name} {icon}";
            "format-icons" = {
              locked = "\uf023";
              unlocked = "\uf09c";
            };
          };
          tray = {
            "icon-size" = 21;
            spacing = 10;
          };
          clock = {
            format = "{:%H:%M %a}";
            #"on-click" = "ags -t calendar";
            tooltip = false;
          };
          "custom/system" = {
            format = "\ue473";
            tooltip = false;
          };
          cpu = {
            format = "/ C {usage}% ";
            #"on-click" = "~/.config/ml4w/settings/system-monitor.sh";
          };
          memory = {
            format = "/ M {}% ";
            #"on-click" = "~/.config/ml4w/settings/system-monitor.sh";
          };
          disk = {
            interval = 30;
            format = "D {percentage_used}% ";
            path = "/";
            #"on-click" = "~/.config/ml4w/settings/system-monitor.sh";
          };
          "hyprland/language" = {
            format = "/ K {short}";
          };
          "group/hardware" = {
            orientation = "inherit";
            drawer = {
              "transition-duration" = 300;
              "children-class" = "not-memory";
              "transition-left-to-right" = false;
            };
            modules = [
              "custom/system"
              "disk"
              "cpu"
              "memory"
              "hyprland/language"
            ];
          };
          "group/tools" = {
            orientation = "inherit";
            drawer = {
              "transition-duration" = 300;
              "children-class" = "not-memory";
              "transition-left-to-right" = false;
            };
            modules = [
              "custom/tools"
              "custom/cliphist"
              "custom/hypridle"
              "custom/hyprshade"
            ];
          };
          "group/links" = {
            orientation = "horizontal";
            modules = [
              "custom/chatgpt"
              "custom/empty"
            ];
          };
          "group/settings" = {
            orientation = "inherit";
            drawer = {
              "transition-duration" = 300;
              "children-class" = "not-memory";
              "transition-left-to-right" = true;
            };
            modules = [
              "custom/settings"
              "custom/waybarthemes"
              "custom/wallpaper"
            ];
          };
          network = {
            format = "{ifname}";
            "format-wifi" = "   {signalStrength}%";
            "format-ethernet" = "\uf796  {ifname}";
            "format-disconnected" = "Disconnected";
            "tooltip-format" = "\uf796 {ifname} via {gwaddri}";
            "tooltip-format-wifi" = "\uf1eb  {ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
            "tooltip-format-ethernet" = "\uf796 {ifname}\nIP: {ipaddr}\n up: {bandwidthUpBits} down: {bandwidthDownBits}";
            "tooltip-format-disconnected" = "Disconnected";
            "max-length" = 50;
            #"on-click" = "~/.config/ml4w/settings/networkmanager.sh";
            #"on-click-right" = "~/.config/ml4w/scripts/nm-applet.sh toggle";
          };
          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            "format-charging" = "\uf5e7  {capacity}%";
            "format-plugged" = "\uf1e6  {capacity}%";
            "format-alt" = "{icon}  {time}";
            "format-icons" = [
              "\uf244 "
              "\uf243 "
              "\uf242 "
              "\uf241 "
              "\uf240 "
            ];
          };
          pulseaudio = {
            format = "{icon}  {volume}%";
            "format-bluetooth" = "{volume}% {icon}\uf294 {format_source}";
            "format-bluetooth-muted" = "\uf6a9 {icon}\uf294 {format_source}";
            "format-muted" = "\uf6a9 {format_source}";
            "format-source" = "{volume}% \uf130";
            "format-source-muted" = "\uf131";
            "format-icons" = {
              headphone = "\uf025 ";
              "hands-free" = "\uf590 ";
              headset = "\uf590 ";
              phone = "\uf095 ";
              portable = "\uf095 ";
              car = "\uf1b9 ";
              default = [
                "\uf026"
                "\uf028"
                "\uf028"
              ];
            };
            "on-click" = "pavucontrol";
          };
          bluetooth = {
            format = "\uf293 {status}";
            "format-disabled" = "";
            "format-off" = "";
            interval = 30;
            "on-click" = "blueman-manager";
            "format-no-controller" = "";
          };
          user = {
            format = "{user}";
            interval = 60;
            icon = false;
          };
          backlight = {
            format = "{icon} {percent}%";
            "format-icons" = [
              "\ue38d"
              "\ue3d4"
              "\ue3d3"
              "\ue3d2"
              "\ue3d1"
              "\ue3d0"
              "\ue3cf"
              "\ue3ce"
              "\ue3cd"
              "\ue3cc"
              "\ue3cb"
              "\ue3ca"
              "\ue3c9"
              "\ue3c8"
              "\ue39b"
            ];
            "scroll-step" = 1;
          };
        }
    ];
    style = concatStrings [
      ''
        /*
         * __        __          _                  ____  _         _
         * \ \      / /_ _ _   _| |__   __ _ _ __  / ___|| |_ _   _| | ___
         *  \ \ /\ / / _` | | | | '_ \ / _` | '__| \___ \| __| | | | |/ _ \
         *   \ V  V / (_| | |_| | |_) | (_| | |     ___) | |_| |_| | |  __/
         *    \_/\_/ \__,_|\__, |_.__/ \__,_|_|    |____/ \__|\__, |_|\___|
         *                 |___/                              |___/
         *
         * -----------------------------------------------------
        */

        /* -----------------------------------------------------
         * Import Pywal colors
         * ----------------------------------------------------- */
        /* @import 'style-light.css'; */

        /* -----------------------------------------------------
         * General
         * ----------------------------------------------------- */

        * {
            font-family: "Fira Sans Semibold", "Font Awesome 6 Free", Material Design Icons, FontAwesome, Roboto, Helvetica, Arial, sans-serif;
            border: none;
            border-radius: 0px;
        }

        window#waybar {
            background-color: rgba(0,0,0,0.2);
            border-bottom: 0px solid #ffffff;
            /* color: #FFFFFF; */
            transition-property: background-color;
            transition-duration: .5s;
        }

        .modules-left {
            padding-left:14px;
        }

        /* -----------------------------------------------------
         * Workspaces
         * ----------------------------------------------------- */

        #workspaces {
            background: @workspacesbackground1;
            margin: 5px 1px 6px 1px;
            padding: 0px 1px;
            border-radius: 15px;
            border: 0px;
            font-weight: bold;
            font-style: normal;
            opacity: 0.8;
            font-size: 16px;
            color: @textcolor1;
        }

        #workspaces button {
            padding: 0px 5px;
            margin: 4px 3px;
            border-radius: 15px;
            border: 0px;
            color: @textcolor1;
            background-color: @workspacesbackground2;
            transition: all 0.3s ease-in-out;
            opacity: 0.4;
        }

        #workspaces button.active {
            color: @textcolor1;
            background: @workspacesbackground2;
            border-radius: 15px;
            min-width: 40px;
            transition: all 0.3s ease-in-out;
            opacity:1.0;
        }

        #workspaces button:hover {
            color: @textcolor1;
            background: @workspacesbackground2;
            border-radius: 15px;
            opacity:0.7;
        }

        /* -----------------------------------------------------
         * Tooltips
         * ----------------------------------------------------- */

        tooltip {
            border-radius: 10px;
            background-color: @backgroundlight;
            opacity:0.8;
            padding:20px;
            margin:0px;
        }

        tooltip label {
            color: @textcolor2;
        }

        /* -----------------------------------------------------
         * Window
         * ----------------------------------------------------- */

        #window {
            background: @backgroundlight;
            margin: 8px 15px 8px 0px;
            padding: 2px 10px 0px 10px;
            border-radius: 12px;
            color:@textcolor2;
            font-size:16px;
            font-weight:normal;
            opacity:0.8;
        }

        window#waybar.empty #window {
            background-color:transparent;
        }

        /* -----------------------------------------------------
         * Taskbar
         * ----------------------------------------------------- */

        #taskbar {
            background: @backgroundlight;
            margin: 6px 15px 6px 0px;
            padding:0px;
            border-radius: 15px;
            font-weight: normal;
            font-style: normal;
            opacity:0.8;
            border: 3px solid @backgroundlight;
        }

        #taskbar button {
            margin:0;
            border-radius: 15px;
            padding: 0px 5px 0px 5px;
        }

        #taskbar.empty {
            background:transparent;
            border:0;
            padding:0;
            margin:0;
        }

        /* -----------------------------------------------------
         * Modules
         * ----------------------------------------------------- */

        .modules-left > widget:first-child > #workspaces {
            margin-left: 0;
        }

        .modules-right > widget:last-child > #workspaces {
            margin-right: 0;
        }

        /* -----------------------------------------------------
         * Custom Quicklinks
         * ----------------------------------------------------- */

        #custom-brave,
        #custom-browser,
        #custom-keybindings,
        #custom-outlook,
        #custom-filemanager,
        #custom-teams,
        #custom-chatgpt,
        #custom-calculator,
        #custom-windowsvm,
        #custom-cliphist,
        #custom-wallpaper,
        #custom-settings,
        #custom-system,
        #custom-hyprshade,
        #custom-hypridle,
        #custom-tools,
        #custom-quicklink1,
        #custom-quicklink2,
        #custom-quicklink3,
        #custom-quicklink4,
        #custom-quicklink5,
        #custom-quicklink6,
        #custom-quicklink7,
        #custom-quicklink8,
        #custom-quicklink9,
        #custom-quicklink10,
        #custom-waybarthemes {
            margin-right: 14px;
            font-size: 20px;
            font-weight: bold;
            opacity: 0.8;
            color: @iconcolor;
        }

        #custom-quicklink1,
        #custom-quicklink2,
        #custom-quicklink3,
        #custom-quicklink4,
        #custom-quicklink5,
        #custom-quicklink6,
        #custom-quicklink7,
        #custom-quicklink8,
        #custom-quicklink9,
        #custom-quicklink10 {
            margin-right: 20px;
        }

        #custom-settings {
            margin-right:12px;
        }

        #custom-tools {
            margin-right:12px;
        }

        #custom-hypridle.active {
            color: @iconcolor;
        }

        #custom-hypridle.notactive {
            color: #dc2f2f;
        }

        #custom-ml4w-welcome {
            margin-right: 12px;
            background-image: url("../assets/ml4w-icon.svg");
            background-position: center;
            background-repeat: no-repeat;
            background-size: contain;
            padding-right: 20px;
            opacity: 0.8;
        }

        #custom-chatgpt {
            margin-right: 12px;
            background-image: url("../assets/openai.svg");
            background-repeat: no-repeat;
            background-position: center;
            background-size: contain;
            padding-right: 16px;
            opacity: 0.8;
        }

        /* -----------------------------------------------------
         * Idle Inhibator
         * ----------------------------------------------------- */

        #idle_inhibitor {
            margin-right: 17px;
            font-size: 20px;
            font-weight: bold;
            opacity: 0.8;
            color: @iconcolor;
        }

        #idle_inhibitor.activated {
            margin-right: 15px;
            font-size: 20px;
            font-weight: bold;
            opacity: 0.8;
            color: #dc2f2f;
        }

        /* -----------------------------------------------------
         * Custom Modules
         * ----------------------------------------------------- */

        #custom-appmenu {
            background-color: @backgrounddark;
            font-size: 16px;
            color: @textcolor1;
            border-radius: 15px;
            padding: 0px 10px 0px 10px;
            margin: 8px 16px 8px 0px;
            opacity:0.8;
            border:3px solid @bordercolor;
        }

        /* -----------------------------------------------------
         * Custom Exit
         * ----------------------------------------------------- */

        #custom-exit {
            margin: 0px 13px 0px 0px;
            padding:0px;
            font-size:20px;
            color: @iconcolor;
            opacity: 0.8;
        }

        /* -----------------------------------------------------
         * Custom Updates
         * ----------------------------------------------------- */

        #custom-updates {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
        }

        #custom-updates.green {
            background-color: @backgroundlight;
        }

        #custom-updates.yellow {
            background-color: #ff9a3c;
            color: #FFFFFF;
        }

        #custom-updates.red {
            background-color: #dc2f2f;
            color: #FFFFFF;
        }

        /* -----------------------------------------------------
         * Hardware Group
         * ----------------------------------------------------- */

         #disk,#memory,#cpu,#language {
            margin:0px;
            padding:0px;
            font-size:16px;
            color:@iconcolor;
        }

        #language {
            margin-right:10px;
        }

        /* -----------------------------------------------------
         * Clock
         * ----------------------------------------------------- */

        #clock {
            background-color: @backgrounddark;
            font-size: 16px;
            color: @textcolor1;
            border-radius: 15px;
            padding: 1px 10px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
            border:3px solid @bordercolor;
        }

        /* -----------------------------------------------------
         * Backlight
         * ----------------------------------------------------- */

         #backlight {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
        }

        /* -----------------------------------------------------
         * Pulseaudio
         * ----------------------------------------------------- */

        #pulseaudio {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
        }

        #pulseaudio.muted {
            background-color: @backgrounddark;
            color: @textcolor1;
        }

        /* -----------------------------------------------------
         * Network
         * ----------------------------------------------------- */

        #network {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
        }

        #network.ethernet {
            background-color: @backgroundlight;
            color: @textcolor2;
        }

        #network.wifi {
            background-color: @backgroundlight;
            color: @textcolor2;
        }

        /* -----------------------------------------------------
         * Bluetooth
         * ----------------------------------------------------- */

         #bluetooth, #bluetooth.on, #bluetooth.connected {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 10px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
        }

        #bluetooth.off {
            background-color: transparent;
            padding: 0px;
            margin: 0px;
        }

        /* -----------------------------------------------------
         * Battery
         * ----------------------------------------------------- */

        #battery {
            background-color: @backgroundlight;
            font-size: 16px;
            color: @textcolor2;
            border-radius: 15px;
            padding: 2px 15px 0px 10px;
            margin: 8px 15px 8px 0px;
            opacity:0.8;
        }

        #battery.charging, #battery.plugged {
            color: @textcolor2;
            background-color: @backgroundlight;
        }

        @keyframes blink {
            to {
                background-color: @backgroundlight;
                color: @textcolor2;
            }
        }

        #battery.critical:not(.charging) {
            background-color: #f53c3c;
            color: @textcolor3;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }

        /* -----------------------------------------------------
         * Tray
         * ----------------------------------------------------- */

        #tray {
            padding: 0px 15px 0px 0px;
            color: @textcolor3;
        }

        #tray > .passive {
            -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
            -gtk-icon-effect: highlight;
        }
      ''
    ];
  };
}
