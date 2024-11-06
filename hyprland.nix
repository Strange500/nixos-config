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
          };
      bind =
  };

}