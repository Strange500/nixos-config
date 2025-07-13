{lib, ...}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = ["HDMI-A-1, 1920x1080, 0x0, 1" "DP-2, 2560x1440@144, 1920x0, 1"];
      };
      auto-update = false;
      apps = {
        sync = {
          desktop.enable = false;
          game.enable = true;
        };
        dev = {
          enable = true;
          jetbrains.enable = false;
        };
        media = true;
        crypto = true;
      };
      gaming = true;
      desktop.loginManager = lib.mkForce "none";
      desktop.desktopEnvironment = lib.mkForce "kde";
      settings.bluetooth.enable = false;
    };
  };
}
