{...}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = ["HDMI-A-1, 1920x1080, 0x0, 1" "DP-2, 2560x1440@144, 1920x0, 1"];
      };
      remote-access = {
        enable = true;
        tailscale.enable = true;
        sunshine.enable = false;
      };
      apps = {
        sync = {
          desktop.enable = true;
          game.enable = false;
        };
        dev = {
          enable = true;
          jetbrains.enable = false;
        };
        media = true;
        crypto = true;
      };
      gaming = true;
    };
  };
}
