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
        dev = {
          enable = true;
          jetbrains.enable = true;
          vbox.enable = true;
        };
        media = true;
        crypto = true;
      };
      gaming = true;
    };
  };
}
