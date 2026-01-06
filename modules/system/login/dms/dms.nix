{
  config,
  lib,
  ...
}: {
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri"; # Or "hyprland" or "sway"
    configFiles = lib.mkForce [
      "/home/strange/.config/DankMaterialShell/settings.json"
    ];
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
    configHome = "/home/${config.qgroget.user.username}";
  };
}
