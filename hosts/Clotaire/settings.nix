{...}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = [", preferred, auto, 1"];
      };
      remote-access = {
        enable = true;
        tailscale.enable = true;
        sunshine.enable = false;
      };
      apps = {
        school = true;
        sync = {
          desktop.enable = false;
          game.enable = false;
        };
        dev = {
          enable = true;
          jetbrains.enable = true;
        };
        media = false;
        crypto = true;
      };
      gaming = false;
    };
  };
}
