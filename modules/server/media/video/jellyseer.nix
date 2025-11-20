{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.qgroget.server.jellyseerr;
in {
  options.qgroget.server.jellyseerr = {
    enable = mkEnableOption "Custom Jellyseerr setup with persistent config and Traefik integration";

    port = mkOption {
      type = types.port;
      default = 5055;
      description = "Internal port for Jellyseerr web UI.";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${config.services.jellyseerr.configDir} 0755 jellyseerr jellyseerr -"
      "d ${config.services.jellyseerr.configDir}/db 0755 jellyseerr jellyseerr -"
      "d ${config.services.jellyseerr.configDir}/logs 0755 jellyseerr jellyseerr -"
      "Z ${config.services.jellyseerr.configDir} - jellyseerr jellyseerr -"
    ];

    qgroget.services = {
      jellyseerr = {
        name = "jellyseerr";
        url = "http://127.0.0.1:${toString config.services.jellyseerr.port}";
        type = "public";
        journalctl = true;
        unitName = "jellyseerr.service";
        persistedData = [
          "${config.services.jellyseerr.configDir}"
        ];
        backupDirectories = [
          "${config.services.jellyseerr.configDir}"
        ];
      };
    };

    users.users.jellyseerr = {
      isSystemUser = true;
      description = "Jellyseerr user";
      group = "jellyseerr";
    };
    users.groups.jellyseerr = {
    };

    services.jellyseerr = {
      openFirewall = false;
      enable = true;
      port = cfg.port;
    };

    systemd.services.jellyseerr.serviceConfig.DynamicUser = lib.mkForce false;
    systemd.services.jellyseerr.serviceConfig.User = "jellyseerr";
  };
}
