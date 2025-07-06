{...}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = ["DP-1, 1920x1080, 0x0, 1"];
      };
      apps = {
        sync = true;
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
