{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.server.jellyfin;
in {
  config = lib.mkIf cfg.enable {
    # A separate, age-encrypted dotenv file avoids requiring the private age key
    # to update the existing secrets.yaml. systemd reads it as root, not Nix.
    sops.secrets."server/jellarr/env" = {
      sopsFile = ../../../../secrets/jellarr.env;
      format = "dotenv";
      key = "";
      mode = "0400";
      restartUnits = ["jellarr.service"];
    };

    services.jellarr = {
      enable = true;
      environmentFile = config.sops.secrets."server/jellarr/env".path;
      schedule = "hourly";
      # Never stop Jellyfin or write directly into its live database.
      bootstrap.enable = false;
      config = {
        version = 1;
        base_url = "http://127.0.0.1:${toString cfg.port}";
        # Required by Jellarr's runtime schema; no system settings are managed.
        system = {};
        # Read from the running server's public Branding/Configuration API.
        # Other sections are intentionally absent until an authenticated export
        # is possible; repository defaults are not evidence of runtime state.
        branding = {
          loginDisclaimer = "";
          customCss = "";
          splashscreenEnabled = true;
        };
      };
    };

    systemd.services.jellarr = {
      after = ["jellyfin.service" "sops-install-secrets.service"];
      wants = ["jellyfin.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [config.services.jellarr.dataDir];
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        TimeoutStartSec = "180s";
      };
    };
  };
}
