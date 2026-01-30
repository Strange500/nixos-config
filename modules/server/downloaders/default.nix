{
  config,
  pkgs,
  lib,
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
    user = "${toString config.users.users.arr.uid}:${toString config.users.groups.downloaders.gid}";
    dns = [
      "94.140.14.140"
      "94.140.14.141"
    ];
  };

  qbitEnv = {
    PUID = toString config.users.users.arr.uid;
    PGID = toString config.users.groups.downloaders.gid;
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
      "MemoryWorkingSetLimit" = 256;
    };

    AutoRun = {
      enabled = false;
      program = "";
    };
    BitTorrent = {
      # --- CRITICAL IO FIXES ---

      # 1. Enable Queueing. Without this, MaxActiveDownloads is ignored.
      "Session\\QueueingSystemEnabled" = true;

      # 2. Drastically lower concurrency.
      # Writing 3 files sequentially is faster than 200 simultaneously.
      # (Value is per-instance, so 3 instances = 9 active downloads total)
      "Session\\MaxActiveDownloads" = 3;
      "Session\\MaxActiveTorrents" = 15;
      "Session\\MaxActiveCheckingTorrents" = 1; # Only check 1 file at a time per instance

      # 3. Cache Strategy: Trade RAM for Disk Health
      # Increase Cache: 256MB is too small for modern speeds. Use 512MB or 1024MB if you have RAM.
      "Session\\DiskCache" = 1024;
      # Increase TTL: Keep data in RAM longer (10 mins) to allow larger write chunks.
      "Session\\DiskCacheTTL" = 600;
      # DISABLE OS Cache: Prevent Windows/Linux from double-caching and flushing randomly.
      # This forces the app to use the explicit DiskCache defined above.
      "Session\\UseOSCache" = false;
      "Session\\CoalesceReadWrite" = true; # Merge small reads/writes into big ones

      # 4. Threading
      # Hashing is CPU and IO intensive. 10 threads will kill a mechanical drive.
      "Session\\HashingThreadsCount" = 1;
      "Session\\AsyncIOThreadsCount" = 4; # Default is usually 4, 10 is overkill

      # --- NETWORK & CONNECTIONS ---
      "Session\\MaxConnections" = 200; # Lower global peers to reduce random read requests
      "Session\\MaxConnectionsPerTorrent" = 40;
      "Session\\MaxUploads" = 100; # Too many upload slots = death by random reads
      "Session\\MaxUploadsPerTorrent" = 4;

      # --- STANDARD SETTINGS (Kept from your config) ---
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
      "Session\\GlobalMaxRatio" = 50;
      "Session\\UseReadCache" = true;
      "Session\\FilePoolSize" = 2000; # INCREASED: Keep file handles open to avoid opening/closing files constantly
      "Session\\Port" = "@OUTGOING_PORT@";
      "Session\\Preallocation" = true; # Keep true to prevent fragmentation
      "Session\\SSL\\Port" = 7633;
      "Session\\SendBufferWatermark" = 1000;
      "Session\\SendBufferWatermarkFactor" = 100;
      "Session\\ShareLimitAction" = "Stop";
      "Session\\SubcategoriesEnabled" = true;
      "Session\\Tags" = "cross-seed";
      "Session\\TempPath" = "/temp/torrents"; # Ensure this path is on an SSD!
      "Session\\TempPathEnabled" = true;
      "Session\\TorrentExportDirectory" = "";
      "Session\\UseAlternativeGlobalSpeedLimit" = false;
      "Session\\uTPRateLimited" = true;
    };
    Core = {
      AutoDeleteAddedTorrentFile = "IfAdded";
    };

    LegalNotice = {
      Accepted = true;
    };

    Meta = {
      MigrationVersion = 8;
    };

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
      "WebUI\\RootFolder" = "";
      "WebUI\\ServerDomains" = "*";
      "WebUI\\TrustedReverseProxiesList" = "127.0.0.1/32";
      "WebUI\\Username" = "@USERNAME@";
    };

    RSS = {
      "AutoDownloader\\DownloadRepacks" = false;
      "AutoDownloader\\SmartEpisodeFilter" = ''s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"'';
    };
  };

  qbitPrestartScript = pkgs.writeShellApplication {
    name = "qbit-prestart";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
    ];
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
  environment.etc."tmpfiles.d/downloaders.conf".text = ''
    Z ${config.qgroget.server.containerDir}/qbittorrent 0700 arr downloaders -
    Z ${config.qgroget.server.containerDir}/qbittorrent_bis 0700 arr downloaders -
    Z ${config.qgroget.server.containerDir}/qbittorrent_nyaa 0700 arr downloaders -
    Z /persist/temp/torrent1 0700 arr downloaders -
    Z /persist/temp/torrent2 0700 arr downloaders -
    Z /persist/temp/torrent3 0700 arr downloaders -

  '';

  users.groups.downloaders = {
    gid = 972;
  };
  users.groups.music = {
    gid = 971;
  };

  qgroget.backups.torrent = {
    paths = [
      "${config.qgroget.server.containerDir}/qbittorrent"
      "${config.qgroget.server.containerDir}/qbittorrent_bis"
      "${config.qgroget.server.containerDir}/qbittorrent_nyaa"
      #"${config.qgroget.server.containerDir}/nicotine"
      "${config.qgroget.server.containerDir}/gluetun"
    ];
    systemdUnits = [
      "${cfg.podName}-pod.service"
    ];
  };

  boot.kernelModules = ["wireguard"];

  sops.secrets = {
    "server/gluetun/env" = {
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
          #"${toString cfg.ports.nicotine}:6080"
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
              }
              // qbitEnv;
            volumes = [
              "${cfg.containerDir}/qbittorrent/config:/config:Z"
              "/mnt/data/media/torrents:/data/torrents:Z"
              "/mnt/data/media/torrents:/media/torrents:Z"
              "/persist/temp/torrent1:/temp/torrents:Z"
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
              }
              // qbitEnv;
            volumes = [
              "${cfg.containerDir}/qbittorrent_bis/config:/config:Z"
              "/mnt/data/media:/data:Z"
              "/mnt/data/media:/media:Z"
              "/persist/temp/torrent2:/temp/torrents:Z"
            ];
          }
          // commonContainerConfig;
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
              }
              // qbitEnv;
            volumes = [
              "${cfg.containerDir}/qbittorrent_nyaa/config:/config:Z"
              "/mnt/data/media:/data:Z"
              "/mnt/data/media:/media:Z"
              "/persist/temp/torrent3:/temp/torrents:Z"
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

      # nicotine-plus = {
      #   autoStart = true;
      #   containerConfig = {
      #     name = cfg.containers.nicotinePlus;
      #     image = images.nicotinePlus;
      #     pod = pods.${cfg.podName}.ref;
      #     environments =
      #       commonEnv
      #       // {
      #         PUID = toString config.users.users.beets.uid;
      #         PGID = toString config.users.groups.music.gid;
      #       };
      #     volumes = [
      #       "${cfg.containerDir}/nicotine:/config:Z"
      #       "/mnt/data/music:/music:Z"
      #     ];
      #     #user = "${toString config.users.users.nicotine.uid}:${toString config.users.groups.music.gid}";
      #   };
      #   serviceConfig = commonServiceConfig;
      #   unitConfig = {
      #     Requires = [containers.gluetun.ref];
      #     After = [containers.gluetun.ref];
      #   };
      # };
    };
  };

  environment.etc."qbittorrent.conf.template".source = qbittorrentConf;
}
