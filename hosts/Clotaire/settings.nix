{...}: {
  config = {
    qgroget.nixos = {
      auto-update = false;
      theme = "wide";
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
          vbox.enable = false;
        };
        media = true;
        crypto = true;
      };
      gaming = true;
      vr = true;
    };
  };
}
