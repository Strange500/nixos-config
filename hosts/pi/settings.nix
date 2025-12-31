{lib, ...}: {
  config = {
    qgroget = {
      # server = {
      #   domain = "qgroget.com";
      #   test.enable = false;
      # };
      nixos = {
        settings = {
          bluetooth = {
            enable = false;
          };
        };
        auto-update = false;
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
          basic = false;
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
  };
}
