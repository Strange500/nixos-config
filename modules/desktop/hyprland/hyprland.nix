{
  config,
  lib,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = config.qgroget.nixos.desktop.monitors;

      "$terminal" = "kitty";
      "$fileManager" = "yazi";
      "$menu" = "wofi --show drun";

      exec-once = [
        "blueman-tray"
        "nm-applet"
        "hyprpanel"
        "openrgb --startminimized -p default"
        "hypridle"
        "systemctl --user start hyprpolkitagent"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
      ];

      general = {
        gaps_in = 10;
        gaps_out = 14;
        border_size = 3;
        #"col.active_border" = "$color11";
        #"col.inactive_border" = "rgba(ffffffff)";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.8;
        fullscreen_opacity = 1.0;

        shadow = {
          enabled = true;
          color = lib.mkDefault "0x66000000";
          range = 30;
          render_power = 3;
        };

        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = "on";
          ignore_opacity = true;
          xray = true;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];

        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "borderangle, 1, 30, liner, loop"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
        ];
      };

      dwindle = {
        pseudotile = "true"; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = "true"; # You probably want this
      };

      master = {new_status = "master";};

      misc = {
        force_default_wallpaper =
          -1; # Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo =
          true; # If true disables the random hyprland logo / anime girl background. :(
      };

      input = {
        kb_layout = "fr";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        numlock_by_default = true;

        follow_mouse = 1;

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

        touchpad = {natural_scroll = false;};
      };

      gestures = {workspace_swipe = false;};

      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      binds = {
        workspace_back_and_forth = true;
        allow_workspace_cycles = true;
        pass_mouse_when_bound = false;
      };

      "$mainMod" = "SUPER";
      # Sets "Windows" key as main modifier
      bind = [
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, $menu"
        "$mainMod, P, pseudo," # dwindle
        "$mainMod, J, togglesplit," # dwindle

        "$mainMod, W, exec, wlogout"

        # Move focus with mainMod + arrow keys
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "SUPER, ampersand, workspace, 1"
        "SUPER, eacute, workspace, 2"
        "SUPER, quotedbl, workspace, 3"
        "SUPER, apostrophe, workspace, 4"
        "SUPER, parenleft, workspace, 5"
        "SUPER, egrave, workspace, 6"
        "SUPER, minus, workspace, 7"
        "SUPER, underscore, workspace, 8"
        "SUPER, ccedilla, workspace, 9"
        "SUPER, agrave, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "SUPER_SHIFT, ampersand, movetoworkspace, 1"
        "SUPER_SHIFT, eacute, movetoworkspace, 2"
        "SUPER_SHIFT, quotedbl, movetoworkspace, 3"
        "SUPER_SHIFT, apostrophe, movetoworkspace, 4"
        "SUPER_SHIFT, parenleft, movetoworkspace, 5"
        "SUPER_SHIFT, egrave, movetoworkspace, 6"
        "SUPER_SHIFT, minus, movetoworkspace, 7"
        "SUPER_SHIFT, underscore, movetoworkspace, 8"
        "SUPER_SHIFT, ccedilla, movetoworkspace, 9"
        "SUPER_SHIFT, agrave, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, exec, hyprctl dispatch workspace r-1"
        "$mainMod, mouse_up, exec, hyprctl dispatch workspace r+1"

        # launch Rofi
        "$mainMod Control_L, RETURN , exec, rofi -show drun -show-icons"

        # Screenshot
        ''
          $mainMod Control_L, S, exec, grim -g "$(slurp)" $HOME/Images/$(date +'%s_grim.png')''

        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
        ", F1, exec, brightnessctl set 10%-"
        ", F2, exec, brightnessctl set +10%"
      ];

      # Browser Picture in Picture
      windowrulev2 = [
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "move 69.5% 4%, title:^(Picture-in-Picture)$"
      ];
    };
  };

  home.packages = [
    pkgs.hyprpanel
    pkgs.swww
    pkgs.grim
    pkgs.slurp
  ];

  programs.rofi = {
    enable = true;
    theme = lib.mkForce "/home/${config.qgroget.user.username}/.local/share/rofi/themes/theme.rasi";
  };

  systemd.user.services.wallapaper-cycle = {
    Unit = {
      Description = "Cycle wallpaper using swww";
      After = ["hyprland-session.target"];
    };
    Install = {WantedBy = ["hyprland-session.target"];};
    Service = {
      Type = "simple";
      ExecStart = "${
        pkgs.writeShellScript "wallpaper-cycle.sh" ''
          # This script automatically changes wallpaper for Linux desktop using Hyprland as DP

          WAIT=300
          dir=$1
          trans_type="any"

          swww-daemon &

          # Define the function for setting wallpapers in Hyprland
          set_wallpaper_hyprland() {
              BG="$(find "$dir" -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' | shuf -n1)"
              PROGRAM="swww-daemon"

              for dp in $(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}'); do
                  BG="$(find "$dir" -name '*.jpg' -o -name '*.png' | shuf -n1)"
                  swww img "$BG" --transition-fps 244 --transition-type "$trans_type" --transition-duration 1 -o "$dp"
                  sleep 1
              done

          }

          # Main loop to check for monitor configuration changes and update wallpaper
          while true; do
              initial_monitors=$(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}')
              set_wallpaper_hyprland
              # Wait for the specified amount of time or until a monitor configuration change
              for ((i=1; i<=WAIT; i++)); do
                  current_monitors=$(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}')
                  if [ "$initial_monitors" != "$current_monitors" ]; then
                      echo "Monitor configuration changed. Breaking out of the loop."
                      break
                  fi
                  sleep 1
              done
          done
        ''
      } /home/${config.qgroget.user.username}/wallpaper/current";
    };
  };
}
