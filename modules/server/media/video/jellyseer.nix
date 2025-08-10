{config, ...}: {
  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /containers/jellyseer 0755 jellyseer jellyseer -"
    "d /containers/jellyseer/config 0755 jellyseer jellyseer -"
    "d /containers/jellyseer/config/logs 0755 jellyseer jellyseer -"
    "Z /containers/jellyseer/config/logs/jellyseerr.log 0644 jellyseer jellyseer -"
  ];

  qgroget.services = {
    jellyseer = {
      name = "jellyseer";
      url = "http://127.0.0.1:5055";
      type = "public";
      journalctl = true;
      unitName = "jellyseer.service";
    };
  };

  virtualisation.quadlet = {
    containers.jellyseer = {
      autoStart = true;
      containerConfig = {
        name = "jellyseer";
        image = "ghcr.io/fallenbagel/jellyseerr:latest";
        environments = {
          LOG_LEVEL = "info";
          TZ = "Europe/Paris";
        };
        publishPorts = ["5055:5055"];
        volumes = [
          "${config.qgroget.server.containerDir}/jellyseer/config:/app/config:Z"
        ];
      };
      serviceConfig = {
        Restart = "unless-stopped";
      };
    };
  };
}
