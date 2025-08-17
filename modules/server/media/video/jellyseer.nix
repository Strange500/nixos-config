{
  config,
  lib,
  ...
}: {
  systemd.tmpfiles.rules = [
    "d ${config.services.jellyseerr.configDir} 0755 jellyseerr jellyseerr -"
    "d ${config.services.jellyseerr.configDir}/db 0755 jellyseerr jellyseerr -"
    "d ${config.services.jellyseerr.configDir}/logs 0755 jellyseerr jellyseerr -"
    "Z ${config.services.jellyseerr.configDir} - jellyseerr jellyseerr -"
  ];

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
    port = 5055;
  };

  systemd.services.jellyseerr.serviceConfig.DynamicUser = lib.mkForce false;
  systemd.services.jellyseerr.serviceConfig.User = "jellyseerr";
}
