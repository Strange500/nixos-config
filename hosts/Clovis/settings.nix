{...}: {
  config = {
    qgroget.nixos = {
      auto-update = false;
      theme = "wide";
      desktop = {
        monitors = [
          "DP-2, preferred, 0x0, 1"
          "HDMI-A-1, preferred, 1920x0, 1"
        ];
      };
      remote-access = {
        enable = true;
        tailscale.enable = true;
        sunshine.enable = false;
      };
      apps = {
        school = true;

        dev = {
          enable = true;
          jetbrains.enable = true;
        };
        media = true;
        crypto = true;
      };
      gaming = true;
    };
  };
}
