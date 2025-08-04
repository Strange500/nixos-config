{config, ...}: let
  # Configuration constants
  cfg = {
    containerDir = "${config.qgroget.server.containerDir}";
    mediaDir = config.qgroget.server.mediaDir;
    podName = "downloaders";

    ports = {
      qbittorrent1 = 8112;
      qbittorrent2 = 8113;
      qbittorrent3 = 8114;
      nicotine = 6080;
    };

    containers = {
      nicotinePlus = "nicotine-plus";
      gluetun = "gluetun";
      qbittorrent = "qbittorrent";
      qbittorrentBis = "qbittorrent_bis";
      qbittorrentNyaa = "qbittorrent_nyaa";
    };
  };

  commonEnv = {
    TZ = "Etc/UTC";
  };

  commonContainerConfig = {
    user = "1000:1000";
  };

  commonServiceConfig = {
    Restart = "unless-stopped";
  };

  images = {
    gluetun = "qmcgaw/gluetun";
    qbittorrent = "lscr.io/linuxserver/qbittorrent:latest";
    nicotinePlus = "ghcr.io/fletchto99/nicotine-plus-docker:latest";
  };

  inherit (config.virtualisation.quadlet) containers pods;
in {
  traefik.services = {
    torrent = {
      name = "torrent";
      url = "http://127.0.0.1:${toString cfg.ports.qbittorrent1}";
      type = "private";
    };

    torrent2 = {
      name = "torrent2";
      url = "http://127.0.0.1:${toString cfg.ports.qbittorrent2}";
      type = "private";
    };

    torrent3 = {
      name = "torrent3";
      url = "http://127.0.0.1:${toString cfg.ports.qbittorrent3}";
      type = "private";
    };

    nicotine = {
      name = "nicotine";
      url = "http://127.0.0.1:${toString cfg.ports.nicotine}";
      type = "private";
    };
  };

  boot.kernelModules = ["wireguard"];

  sops.secrets."server/gluetun/env" = {
  };

  virtualisation.quadlet = {
    pods.${cfg.podName} = {
      autoStart = true;
      podConfig = {
        name = cfg.podName;
        publishPorts = [
          "${toString cfg.ports.nicotine}:6080"
          "${toString cfg.ports.qbittorrent1}:8112"
          "${toString cfg.ports.qbittorrent2}:8113"
          "${toString cfg.ports.qbittorrent3}:8114"
        ];
      };
      serviceConfig = commonServiceConfig;
      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };
    containers = {
      gluetun = {
        autoStart = true;
        containerConfig = {
          name = cfg.containers.gluetun;
          pod = pods.${cfg.podName}.ref;
          image = images.gluetun;
          environmentFiles = [
            config.sops.secrets."server/gluetun/env".path
          ];
          volumes = [
            "${cfg.containerDir}/gluetun:/gluetun:Z"
          ];
          addCapabilities = ["NET_ADMIN"];
          devices = [
            "/dev/net/tun"
          ];
        };
        serviceConfig = commonServiceConfig;
      };

      qbittorrent = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.qbittorrent;
            pod = pods.${cfg.podName}.ref;
            image = images.qbittorrent;
            environments =
              commonEnv
              // {
                WEBUI_PORT = "8112";
              };
            volumes = [
              "${cfg.containerDir}/qbittorrent/config:/config:Z"
              "/mnt/media:/data:Z"
              "/mnt/media:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [containers.gluetun.ref];
          After = [containers.gluetun.ref];
        };
      };

      qbittorrent-bis = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.qbittorrentBis;
            image = images.qbittorrent;
            pod = pods.${cfg.podName}.ref;
            environments =
              commonEnv
              // {
                WEBUI_PORT = "8113";
              };
            volumes = [
              "${cfg.containerDir}/qbittorrent_bis/config:/config:Z"
              "/mnt/media:/data:Z"
              "/mnt/media:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [containers.gluetun.ref];
          After = [containers.gluetun.ref];
        };
      };

      qbittorrent-nyaa = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.qbittorrentNyaa;
            image = images.qbittorrent;
            pod = pods.${cfg.podName}.ref;
            environments =
              commonEnv
              // {
                WEBUI_PORT = "8114";
              };
            volumes = [
              "${cfg.containerDir}/qbittorrent_nyaa/config:/config:Z"
              "/mnt/media:/data:Z"
              "/mnt/media:/media:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [containers.gluetun.ref];
          After = [containers.gluetun.ref];
        };
      };

      nicotine-plus = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.nicotinePlus;
            image = images.nicotinePlus;
            pod = pods.${cfg.podName}.ref;
            environments = commonEnv;
            volumes = [
              "${cfg.containerDir}/nicotine:/config:Z"
              "/mnt/music:/music:Z"
            ];
          }
          // commonContainerConfig;
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [containers.gluetun.ref];
          After = [containers.gluetun.ref];
        };
      };
    };
  };
}
