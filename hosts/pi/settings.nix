{lib, ...}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = ["HDMI-A-1, 1920x1080, 0x0, 1" "DP-2, 2560x1440@144, 1920x0, 1"];
      };
      auto-update = false;
      remote-access = {
        enable = true;
        tailscale.enable = false;
        sunshine.enable = false;
      };
      apps = {
        sync = {
          desktop.enable = false;
          game.enable = false;
        };
        dev = {
          enable = false;
          jetbrains.enable = false;
        };
        media = false;
        crypto = false;
      };
      gaming = false;
      vr = false;
      desktop.loginManager = lib.mkForce "none";
      desktop.desktopEnvironment = lib.mkForce "none";
      settings.bluetooth.enable = false;
    };
  };
}
