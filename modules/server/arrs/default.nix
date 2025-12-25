{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = {
    containerDir = "${config.qgroget.server.containerDir}";
    mediaDir = "/mnt/data/media";
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
    user = "${toString config.users.users.arr.uid}:${toString config.users.groups.media.gid}";
  };

  commonServiceConfig = {
    Restart = "always";
  };

  # Build the TOML template in the Nix store (with a placeholder).
  tomlFmt = pkgs.formats.toml {};
  traefikHeaderRaw = {
    http.middlewares."inject-basic-arr".headers.customRequestHeaders.Authorization = "Basic __SECRET__";
  };
  traefikHeaderSecret = tomlFmt.generate "inject-basic-arr.tpl.toml" traefikHeaderRaw;

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
  users.users.arr = {
    isSystemUser = true;
    uid = 980;
    description = "User for running arr services";
    home = "/nonexistent";
    group = "arr";
    createHome = false;
    extraGroups = ["media"];
  };
  users.groups.arr = {};
  users.groups.media = {
    gid = 973;
  };

  qgroget.services = {
    sonarr-anime = {
      name = "sonarr-anime";
      url = "http://127.0.0.1:${toString cfg.ports.sonarr-anime}";
      type = "private";
      middlewares = ["SSO" "inject-basic-arr"];
    };
    radarr-anime = {
      name = "radarr-anime";
      url = "http://127.0.0.1:${toString cfg.ports.radarr-anime}";
      type = "private";
      middlewares = ["SSO" "inject-basic-arr"];
    };
    sonarr = {
      name = "sonarr";
      url = "http://127.0.0.1:${toString cfg.ports.sonarr}";
      type = "private";
      middlewares = ["SSO" "inject-basic-arr"];
    };
    radarr = {
      name = "radarr";
      url = "http://127.0.0.1:${toString cfg.ports.radarr}";
      type = "private";
      middlewares = ["SSO" "inject-basic-arr"];
    };
    bazarr = {
      name = "bazarr";
      url = "http://127.0.0.1:${toString cfg.ports.bazarr}";
      type = "private";
      middlewares = ["SSO" "inject-basic-arr"];
    };
    prowlarr = {
      name = "prowlarr";
      url = "http://127.0.0.1:${toString cfg.ports.prowlarr}";
      type = "private";
      middlewares = ["SSO" "inject-basic-arr"];
    };
  };

  services.authelia.instances.qgroget.settings.access_control.rules = lib.mkAfter [
    {
      domain = "sonarr.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
    {
      domain = "radarr.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
    {
      domain = "sonarr-anime.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
    {
      domain = "radarr-anime.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
    {
      domain = "bazarr.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
    {
      domain = "prowlarr.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
    {
      domain = "jackett.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
  ];

  qgroget.backups.arr = {
    paths = [
      "${cfg.containerDir}/sonarr"
      "${cfg.containerDir}/radarr"
      "${cfg.containerDir}/sonarr-anime"
      "${cfg.containerDir}/radarr-anime"
      "${cfg.containerDir}/bazarr"
    ];
    systemdUnits = [
      "${cfg.podName}-pod.service"
    ];
  };

  environment.etc."tmpfiles.d/arr.conf".text = ''
    Z ${config.services.jackett.dataDir} 0750 arr media -
    Z ${cfg.containerDir}/sonarr 0700 arr media -
    Z ${cfg.containerDir}/radarr 0700 arr media -
    Z ${cfg.containerDir}/sonarr-anime 0700 arr media -
    Z ${cfg.containerDir}/radarr-anime 0700 arr media -
    Z ${cfg.containerDir}/bazarr 0700 arr media -
    Z ${cfg.containerDir}/prowlarr 0700 arr media -
  '';

  sops.secrets = {
    "server/arrs/username" = {
      owner = "traefik";
      group = "traefik";
    };
    "server/arrs/password" = {
      owner = "traefik";
      group = "traefik";
    };
  };

  # inject secret basic token into config file at startup
  systemd.services.traefik = {
    path = [pkgs.coreutils pkgs.gnused];

    serviceConfig = {
      RuntimeDirectory = "traefik";
      RuntimeDirectoryMode = "0700";
      # Make preStart run as root (so it can chown and read secrets),
      PermissionsStartOnly = true;
    };

    preStart = lib.mkAfter ''
      set -euo pipefail

      # Create target dir in tmpfs with tight perms, owned by traefik
      install -d -m 0700 -o traefik -g traefik /run/traefik/secureConf

      username=$(cat ${config.sops.secrets."server/arrs/username".path})
      password=$(cat ${config.sops.secrets."server/arrs/password".path})

      # Build Basic auth (no newline, no wrapping)
      auth="$(printf '%s' "$username:$password" | base64 -w0)"

      tmp="$(mktemp /run/traefik/secureConf/inject-basic-arr.toml.XXXXXX)"
      sed "s#__SECRET__#''${auth}#g" ${traefikHeaderSecret} > "$tmp"

      chown traefik:traefik "$tmp"
      chmod 0600 "$tmp"
      mv -f "$tmp" /run/traefik/secureConf/inject-basic-arr.toml
    '';
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

      prowlarr = {
        autoStart = true;
        containerConfig =
          {
            name = cfg.containers.prowlarr;
            pod = pods.${cfg.podName}.ref;
            image = images.prowlarr;
            volumes = [
              "${cfg.containerDir}/prowlarr/config:/config:Z"
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
    };
  };
}
