{...}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = ["DP-1, 1920x1080, 0x0, 1"];
      };
      remote-access = {
        enable = true;
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
        media = false;
        crypto = false;
      };
      gaming = false;
    };
  };
}
