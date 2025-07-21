{lib, ...}: {
  config = {
    qgroget.nixos = {
      isDesktop = false;
      theme = "wide";
      desktop = {
        desktopEnvironment = lib.mkForce "none";
        loginManager = lib.mkForce "none";
      };
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
    };
  };
}
