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

        dev = {
          enable = true;
          jetbrains.enable = true;
        };
        media = false;
        crypto = false;
      };
      gaming = false;
    };
  };
}
