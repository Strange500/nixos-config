{ pkgs, inputs, config, ...}:

{

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {


      monitor = map
        (m:
          let
            resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
            position = "${toString m.x}x${toString m.y}";
          in
          "${m.name},${if m.enabled then "${resolution},${position},1" else "disable"}"
        )
        (config.monitors);


      "$terminal" = "kitty";
      "$fileManager" = "dolphin";
      "$menu" = "wofi --show drun";

      exec-once = [
        "nm-applet & blueman-tray & waybar"
        "hyprctl setcursor Bibata-Modern-Ice 24"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        ];

      general = {
        gaps_in = 10;
        gaps_out = 14;
        border_size = 3;
        "col.active_border" = "$color11";
        "col.inactive_border" = "rgba(ffffffff)";
        layout = "dwindle";
        resize_on_border = true;

      };


      decoration = {
          rounding = 10;

          # Change transparency of focused and unfocused windows
          active_opacity = 1.0;
          inactive_opacity = 0.8;
          fullscreen_opacity = 1.0;

          #drop_shadow = true;
          #shadow_range = 30;
          #shadow_render_power = 3;
          #"col.shadow" = "0x66000000";

          # https://wiki.hyprland.org/Configuring/Variables/#blur
          blur =  {
            enabled = true;
            size = 6;
            passes = 2;
            new_optimizations = "on";
            ignore_opacity = true;
            xray = true;
            # blurls = waybar
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

      master = {
          new_status = "master";
      };

      misc = {
          force_default_wallpaper = -1 ;# Set to 0 or 1 to disable the anime mascot wallpapers
          disable_hyprland_logo = false; # If true disables the random hyprland logo / anime girl background. :(
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

        touchpad = {
            natural_scroll = false;
        };
      };

      gestures = {
          workspace_swipe = false;
      };

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
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Example special workspace (scratchpad)
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          "$mainMod Control_L, RETURN , exec, rofi -show drun -show-icons"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrule = [
          "tile,^(Microsoft-edge)$"
          "tile,^(Brave-browser)$"
          "tile,^(Chromium)$"
          "float,^(pavucontrol)$"
          "float,^(blueman-manager)$"
          "float,^(nm-connection-editor)$"
          "float,^(qalculate-gtk)$"
      ];

      # Browser Picture in Picture
      windowrulev2 = [
          "float, title:^(Picture-in-Picture)$"
          "pin, title:^(Picture-in-Picture)$"
          "move 69.5% 4%, title:^(Picture-in-Picture)$"
      ];

    };
  };
}