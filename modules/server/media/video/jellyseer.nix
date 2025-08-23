{
  config,
  lib,
  ...
}: {
  # Configure permissions for jellyseerr service
  qgroget.server.permissions.services.jellyseerr = {
    user = "jellyseerr";
    group = "jellyseerr";
    directories = [
      {
        path = "${config.services.jellyseerr.configDir}";
        mode = "0755";
        type = "d";
      }
      {
        path = "${config.services.jellyseerr.configDir}/db";
        mode = "0755";
        type = "d";
      }
      {
        path = "${config.services.jellyseerr.configDir}/logs";
        mode = "0755";
        type = "d";
      }
      {
        path = "${config.services.jellyseerr.configDir}";
        mode = "-";
        type = "Z";
      }
    ];
  };

  qgroget.backups.jellyseerr = {
    paths = [
      "${config.services.jellyseerr.configDir}"
    ];
    systemdUnits = [
      "jellyseerr.service"
    ];
  };

  qgroget.services = {
    jellyseer = {
      name = "jellyseer";
      url = "http://127.0.0.1:${toString config.services.jellyseerr.port}";
      type = "public";
      journalctl = true;
      unitName = "jellyseerr.service";
    };
    jellyseerr = {
      name = "jellyseerr";
      url = "http://127.0.0.1:${toString config.services.jellyseerr.port}";
      type = "public";
      journalctl = true;
      unitName = "jellyseerr.service";
    };
  };

  environment.persistence."/persist".directories = [
    "/var/lib/jellyseerr/config/db"
  ];
  environment.persistence."/persist".files = [
    "${config.services.jellyseerr.configDir}/settings.json"
  ];

  services.jellyseerr = {
    openFirewall = false;
    enable = true;
    port = 5055;
  };

  systemd.services.jellyseerr.serviceConfig.DynamicUser = lib.mkForce false;
  systemd.services.jellyseerr.serviceConfig.User = "jellyseerr";
}
