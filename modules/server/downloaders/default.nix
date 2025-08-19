{
  config,
  pkgs,
  ...
}: let
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

    vpnOutGoingPort = {
      qbittorrent1 = 30402;
      qbittorrent2 = 40656;
      qbittorrent3 = 59078;
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

  ini = pkgs.formats.ini {};

  qbittorrentConfig = {
    Application = {
      "FileLogger\\Age" = 1;
      "FileLogger\\AgeType" = 1;
      "FileLogger\\Backup" = true;
      "FileLogger\\DeleteOld" = true;
      "FileLogger\\Enabled" = true;
      "FileLogger\\MaxSizeBytes" = 66560;
      "FileLogger\\Path" = "/config/qBittorrent/logs";
    };

    AutoRun = {
      enabled = false;
      program = "";
    };

    BitTorrent = {
      "Session\\AddTorrentStopped" = false;
      "Session\\AddTorrentToTopOfQueue" = true;
      "Session\\AddTrackersEnabled" = false;
      "Session\\AdditionalTrackers" = "";
      "Session\\AlternativeGlobalDLSpeedLimit" = 0;
      "Session\\AnonymousModeEnabled" = false;
      "Session\\BTProtocol" = "TCP";
      "Session\\BandwidthSchedulerEnabled" = true;
      "Session\\DefaultSavePath" = "/media/torrents";
      "Session\\DisableAutoTMMByDefault" = false;
      "Session\\DisableAutoTMMTriggers\\CategorySavePathChanged" = false;
      "Session\\DisableAutoTMMTriggers\\DefaultSavePathChanged" = false;
      "Session\\DiskCacheTTL" = 600;
      "Session\\ExcludedFileNames" = "";
      "Session\\FinishedTorrentExportDirectory" = "/media/torrents/torrent_file_backup";
      "Session\\GlobalMaxInactiveSeedingMinutes" = 131400;
      "Session\\GlobalMaxRatio" = -1;
      "Session\\GlobalMaxSeedingMinutes" = 131400;
      "Session\\GlobalUPSpeedLimit" = 10000;
      "Session\\IgnoreLimitsOnLAN" = false;
      "Session\\IgnoreSlowTorrentsForQueueing" = true;
      "Session\\MaxActiveCheckingTorrents" = 3;
      "Session\\MaxActiveDownloads" = 7;
      "Session\\MaxActiveTorrents" = 30000;
      "Session\\MaxActiveUploads" = 250;
      "Session\\MaxUploads" = 1;
      "Session\\MaxUploadsPerTorrent" = 10;
      "Session\\Port" = "@OUTGOING_PORT@";
      "Session\\Preallocation" = true;
      "Session\\QueueingSystemEnabled" = true;
      "Session\\SSL\\Port" = 7633;
      "Session\\SendBufferWatermark" = 1000;
      "Session\\SendBufferWatermarkFactor" = 100;
      "Session\\ShareLimitAction" = "Stop";
      "Session\\SubcategoriesEnabled" = true;
      "Session\\Tags" = "cross-seed";
      "Session\\TempPath" = "/tempdl";
      "Session\\TempPathEnabled" = false;
      "Session\\TorrentExportDirectory" = "";
      "Session\\UseAlternativeGlobalSpeedLimit" = false;
      "Session\\uTPRateLimited" = true;
    };

    Core = {
      AutoDeleteAddedTorrentFile = "IfAdded";
    };

    LegalNotice = {Accepted = true;};

    Meta = {MigrationVersion = 8;};

    Network = {
      PortForwardingEnabled = false;
      "Proxy\\HostnameLookupEnabled" = false;
      "Proxy\\Profiles\\BitTorrent" = true;
      "Proxy\\Profiles\\Misc" = true;
      "Proxy\\Profiles\\RSS" = true;
    };

    Preferences = {
      "Connection\\PortRangeMin" = 6881;
      "Connection\\ResolvePeerCountries" = false;
      "Connection\\UPnP" = false;
      "Downloads\\SavePath" = "/downloads/";
      "Downloads\\TempPath" = "/downloads/incomplete/";
      "General\\DeleteTorrentsFilesAsDefault" = true;
      "General\\Locale" = "en";
      "MailNotification\\password" = "";
      "MailNotification\\req_auth" = true;
      "MailNotification\\username" = "";
      "Scheduler\\end_time" = "@Variant(\\0\\0\\0\\xf\\x1\\xb7t\\0)";
      "Scheduler\\start_time" = "@Variant(\\0\\0\\0\\xf\\0\\x36\\xee\\x80)";
      "WebUI\\Address" = "*";
      "WebUI\\AlternativeUIEnabled" = false;
      "WebUI\\AuthSubnetWhitelist" = "0.0.0.0/0";
      "WebUI\\AuthSubnetWhitelistEnabled" = true;
      "WebUI\\ClickjackingProtection" = false;
      "WebUI\\LocalHostAuth" = false;
      "WebUI\\Password_PBKDF2" = "\"@PASSWORD@\"";
      "WebUI\\Port" = "@PORT@";
      "WebUI\\ReverseProxySupportEnabled" = false;
      "WebUI\\RootFolder" = "/torrentWebUI/2";
      "WebUI\\ServerDomains" = "*";
      "WebUI\\TrustedReverseProxiesList" = "172.16.0.0/20";
      "WebUI\\Username" = "@USERNAME@";
    };

    RSS = {
      "AutoDownloader\\DownloadRepacks" = false;
      "AutoDownloader\\SmartEpisodeFilter" = ''s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"'';
    };
  };

  # ⬇️ New: a small helper that prepares the config per instance
  qbitPrestartScript = pkgs.writeShellApplication {
    name = "qbit-prestart";
    runtimeInputs = with pkgs; [coreutils gnused];
    text = ''
      set -euo pipefail

      TARGET_DIR="$1"   # e.g. /.../qbittorrent/config/qBittorrent
      PORT="$2"         # WebUI port (8112 / 8113 / 8114)
      OUTGOING_PORT="$3" # BitTorrent listen port (e.g. 30402)

      TEMPLATE="/etc/qbittorrent.conf.template"
      USER_FILE='${config.sops.secrets."qbit/user".path}'
      PASS_FILE='${config.sops.secrets."qbit/password".path}'

      USERNAME="$(cat "$USER_FILE")"
      PASSWORD="$(cat "$PASS_FILE")"

      mkdir -p "$TARGET_DIR"
      tmp="$(mktemp)"
      cp "$TEMPLATE" "$tmp"

      # Safely substitute placeholders (escape sed metachars)
      esc() { printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'; }

      sed -i "s|@USERNAME@|$(esc "$USERNAME")|g" "$tmp"
      sed -i "s|@PASSWORD@|$(esc "$PASSWORD")|g" "$tmp"
      sed -i "s|@PORT@|$(esc "$PORT")|g" "$tmp"
      sed -i "s|@OUTGOING_PORT@|$(esc "$OUTGOING_PORT")|g" "$tmp"

      install -m 0644 -D "$tmp" "$TARGET_DIR/qBittorrent.conf"
      chown 1000:1000 "$TARGET_DIR/qBittorrent.conf"
      rm -f "$tmp"
    '';
  };

  qbittorrentConf = ini.generate "qBittorrent.conf" qbittorrentConfig;

  inherit (config.virtualisation.quadlet) containers pods;
in {
  qgroget.services = {
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

  qgroget.backups.torrent = {
    paths = [
      "${config.qgroget.server.containerDir}/qbittorrent"
      "${config.qgroget.server.containerDir}/qbittorrent_bis"
      "${config.qgroget.server.containerDir}/qbittorrent_nyaa"
      "${config.qgroget.server.containerDir}/nicotine"
      "${config.qgroget.server.containerDir}/gluetun"
    ];
    systemdUnits = [
      "${cfg.podName}-pod.service"
    ];
  };

  boot.kernelModules = ["wireguard"];

  sops.secrets = {
    "server/gluetun/env" = {
      restartUnits = [pods.${cfg.podName}.ref];
    };
    "qbit/user" = {
      restartUnits = [
        containers.qbittorrent.ref
        containers.qbittorrent-bis.ref
        containers.qbittorrent-nyaa.ref
      ];
    };
    "qbit/password" = {
      restartUnits = [
        containers.qbittorrent.ref
        containers.qbittorrent-bis.ref
        containers.qbittorrent-nyaa.ref
      ];
    };
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
        serviceConfig =
          commonServiceConfig
          // {
            ExecStartPre = [
              "${qbitPrestartScript}/bin/qbit-prestart ${cfg.containerDir}/qbittorrent/config/qBittorrent ${toString cfg.ports.qbittorrent1} ${toString cfg.vpnOutGoingPort.qbittorrent1}"
            ];
          };
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
        # ⬇️ Add ExecStartPre
        serviceConfig =
          commonServiceConfig
          // {
            ExecStartPre = [
              "${qbitPrestartScript}/bin/qbit-prestart ${cfg.containerDir}/qbittorrent_bis/config/qBittorrent ${toString cfg.ports.qbittorrent2} ${toString cfg.vpnOutGoingPort.qbittorrent2}"
            ];
          };
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
        serviceConfig =
          commonServiceConfig
          // {
            ExecStartPre = [
              "${qbitPrestartScript}/bin/qbit-prestart ${cfg.containerDir}/qbittorrent_nyaa/config/qBittorrent ${toString cfg.ports.qbittorrent3} ${toString cfg.vpnOutGoingPort.qbittorrent3}"
            ];
          };
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

  environment.etc."qbittorrent.conf.template".source = qbittorrentConf;
}
