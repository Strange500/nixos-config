{
  config,
  lib,
  pkgs,
  ...
}: let
  # Configuration constants
  cfg = {
    #uploadLocation = "/mnt/immich";
    uploadLocation = "/mnt/user/immich";
    port = 2283;
  };

  traefikConfig = {
    bufferLimits = 5000000000;
  };
in {
  services.traefik.dynamicConfigOptions = {
    http.middlewares.immich-limit = {
      buffering = {
        maxRequestBodyBytes = traefikConfig.bufferLimits;
        maxResponseBodyBytes = traefikConfig.bufferLimits;
        memResponseBodyBytes = traefikConfig.bufferLimits;
        memRequestBodyBytes = traefikConfig.bufferLimits;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/immich 0700 immich immich -"
    "d /var/lib/immich/assets 0700 immich immich -"
    "d /var/lib/immich/database 0700 immich immich -"
    "d /var/lib/immich/logs 0700 immich immich -"
    "Z /var/lib/immich 0700 immich immich -"
    "Z ${cfg.uploadLocation} 0700 immich immich -"
  ];

  qgroget.services.immich = {
    name = "immich";
    url = "http://[::1]:${toString cfg.port}";
    type = "public";
    middlewares = ["immich-limit"];
    journalctl = true;
    unitName = "immich-server.service";
  };

  services.immich = {
    enable = true;
    port = cfg.port;
  };
}
