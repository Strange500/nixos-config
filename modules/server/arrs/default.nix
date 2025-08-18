{config, ...}: let
  cfg = {
    containerDir = "${config.qgroget.server.containerDir}";
    mediaDir = "/mnt/media";
    podName = "arr";

    ports = {
      sonarr-anime = 8989;
      radarr-anime = 7878;
      sonarr = 9090;
      radarr = 7877;
      bazarr = 6767;
      flaresolverr = 8191;
      prowlarr = 9696;
    };

    containers = {
      sonarrAnime = "sonarr-anime";
      radarrAnime = "radarr-anime";
      sonarr = "sonarr";
      radarr = "radarr";
      bazarr = "bazarr";
      flaresolverr = "flaresolverr";
      prowlarr = "prowlarr";
    };
  };

  commonContainerConfig = {
    user = "1000:1000";
  };

  commonServiceConfig = {
    Restart = "unless-stopped";
  };

  images = {
    sonarrAnime = "lscr.io/linuxserver/sonarr:latest";
    radarrAnime = "lscr.io/linuxserver/radarr:latest";
    sonarr = "lscr.io/linuxserver/sonarr:latest";
    radarr = "lscr.io/linuxserver/radarr:latest";
    bazarr = "lscr.io/linuxserver/bazarr:latest";
    flaresolverr = "ghcr.io/flaresolverr/flaresolverr:latest";
    prowlarr = "lscr.io/linuxserver/prowlarr:latest";
  };

  inherit (config.virtualisation.quadlet) pods;
in {
  qgroget.services = {
    sonarr-anime = {
      name = "sonarr-anime";
      url = "http://127.0.0.1:${toString cfg.ports.sonarr-anime}";
      type = "private";
    };
    radarr-anime = {
      name = "radarr-anime";
      url = "http://127.0.0.1:${toString cfg.ports.radarr-anime}";
      type = "private";
    };
    sonarr = {
      name = "sonarr";
      url = "http://127.0.0.1:${toString cfg.ports.sonarr}";
      type = "private";
    };
    radarr = {
      name = "radarr";
      url = "http://127.0.0.1:${toString cfg.ports.radarr}";
      type = "private";
    };
    bazarr = {
      name = "bazarr";
      url = "http://127.0.0.1:${toString cfg.ports.bazarr}";
      type = "private";
    };
    prowlarr = {
      name = "prowlarr";
      url = "http://127.0.0.1:${toString cfg.ports.prowlarr}";
      type = "private";
    };
  };

  qgroget.backups.arr = {
    paths = [
      "${cfg.containerDir}/sonarr"
      "${cfg.containerDir}/radarr"
      "${cfg.containerDir}/sonarr-anime"
      "${cfg.containerDir}/radarr-anime"
      "${cfg.containerDir}/bazarr"
      "${cfg.containerDir}/prowlarr"
    ];
    systemdUnits = [
      "${cfg.podName}-pod.service"
    ];
  };

  virtualisation.quadlet = {
    pods.${cfg.podName} = {
      autoStart = true;
      podConfig = {
        name = cfg.podName;
        publishPorts = [
          "${toString cfg.ports.sonarr-anime}:8989"
          "${toString cfg.ports.radarr-anime}:7878"
          "${toString cfg.ports.sonarr}:9090"
          "${toString cfg.ports.radarr}:7877"
          "${toString cfg.ports.bazarr}:6767"
          "${toString cfg.ports.flaresolverr}:8191"
          "${toString cfg.ports.prowlarr}:9696"
        ];
      };
      serviceConfig = commonServiceConfig;
      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };
    containers = {
      sonarr = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.sonarr;
            pod = pods.${cfg.podName}.ref;
            image = images.sonarr;
            volumes = [
              "${cfg.containerDir}/sonarr/config:/config:Z"
              "${cfg.mediaDir}:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
      };

      radarr = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.radarr;
            pod = pods.${cfg.podName}.ref;
            image = images.radarr;
            volumes = [
              "${cfg.containerDir}/radarr/config:/config:Z"
              "${cfg.mediaDir}:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
      };

      sonarr-anime = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.sonarrAnime;
            pod = pods.${cfg.podName}.ref;
            image = images.sonarrAnime;
            volumes = [
              "${cfg.containerDir}/sonarr-anime/config:/config:Z"
              "${cfg.mediaDir}:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
      };

      radarr-anime = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.radarrAnime;
            pod = pods.${cfg.podName}.ref;
            image = images.radarrAnime;
            volumes = [
              "${cfg.containerDir}/radarr-anime/config:/config:Z"
              "${cfg.mediaDir}:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
      };

      bazarr = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.bazarr;
            pod = pods.${cfg.podName}.ref;
            image = images.bazarr;
            volumes = [
              "${cfg.containerDir}/bazarr/config:/config:Z"
              "${cfg.mediaDir}:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
      };

      flaresolverr = {
        autoStart = true;
        containerConfig = {
          name = cfg.containers.flaresolverr;
          pod = pods.${cfg.podName}.ref;
          image = images.flaresolverr;
          environments = {
            no_sandbox = "true";
            TZ = "Europe/Paris";
          };
          dns = [
            "94.140.14.140"
            "94.140.14.141"
          ];
        };
        serviceConfig = commonServiceConfig;
      };

      prowlarr = {
        autoStart = true;
        containerConfig = {
          name = cfg.containers.prowlarr;
          pod = pods.${cfg.podName}.ref;
          image = images.prowlarr;
          volumes = [
            "${cfg.containerDir}/prowlarr/config:/config:Z"
          ];
        };
        serviceConfig = commonServiceConfig;
      };
    };
  };
}
