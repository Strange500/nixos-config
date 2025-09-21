{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.qgroget.services;

  # Collections grouped by type
  collections = {
    base = ["crowdsecurity/linux"];
    applications = [
      "LePresidente/jellyfin"
      "LePresidente/jellyseerr"
      "LePresidente/adguardhome"
      "firix/authentik"
      "gauth-fr/immich"
      "sdwilsh/navidrome"
      "Dominic-Wagner/vaultwarden"
    ];
  };

  allCollections = lib.flatten (lib.attrValues collections);

  parsers = [
    "crowdsecurity/syslog-logs"
    "crowdsecurity/dateparse-enrich"
  ];

  # Build acquisition entries per service
  generateAcquisition = service:
    if (service ? journalctl && service.journalctl == true && service ? unitName)
    then {
      source = "journalctl";
      journalctl_filter = ["_SYSTEMD_UNIT=${service.unitName}"];
      labels = {type = service.name;};
    }
    else if (service ? logPath && service.logPath != null)
    then {
      source = "file";
      filenames = [service.logPath];
      labels = {type = service.name;};
      poll_without_inotify = false;
    }
    else {};

  acquisitionsConfig =
    lib.filter (x: x != {}) (map generateAcquisition (lib.attrValues cfg));
in {
  config = {
    sops.secrets."crowdsec/enrollKey" = {
      owner = "crowdsec";
      group = "crowdsec";
    };

    users.users.crowdsec.extraGroups = ["systemd-journal"];

    services.crowdsec = {
      enable = true;

      # Enroll key for console + LAPI
      settings.console.tokenFile = config.sops.secrets."crowdsec/enrollKey".path;

      localConfig = {
        acquisitions = acquisitionsConfig;
      };

      hub = {
        collections = allCollections;
        parsers = parsers;
      };

      autoUpdateService = true;

      #settings.general.api.server.enable = true;
    };
  };
}
