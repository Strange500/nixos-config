{config, ...}: {
  qgroget.services.obsidian = {
    name = "obsidian";
    url = "http://127.0.0.1:5984";
    type = "public";
    middlewares = [
      "obsidiancors"
    ];
  };

  sops.secrets."server/obsidian-livesync/env" = {
  };

  services.traefik.dynamicConfigOptions = {
    http.middlewares.obsidiancors = {
      headers = {
        customResponseHeaders = {
          accessControlAllowMethods = "GET,PUT,POST,HEAD,DELETE";
          accessControlAllowHeaders = "accept,authorization,content-type,origin,referer";
          accessControlAllowOriginList = "app://obsidian.md,capacitor://localhost,http://localhost,https://obsidian.${config.qgroget.server.domain}";
          accessControlMaxAge = "3600";
          addVaryHeader = true;
          accessControlAllowCredentials = true;
        };
      };
    };
  };

  virtualisation.quadlet = {
    containers.obsidian-livesync = {
      autoStart = true;
      containerConfig = {
        name = "obsidian-livesync";
        image = "couchdb:latest";
        environmentFiles = [
          "${config.sops.secrets."server/obsidian-livesync/env".path}"
        ];
        publishPorts = ["5984:5984"];
        volumes = [
          "${config.qgroget.server.containerDir}/obsidianlivesync/data:/opt/couchdb/data:Z"
          "${config.qgroget.server.containerDir}/obsidianlivesync/etc/local.d:/opt/couchdb/etc/local.d:Z"
        ];
      };
      serviceConfig = {
        Restart = "unless-stopped";
      };
    };
  };
}
