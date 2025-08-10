{config, ...}: let
  # Configuration constants
  containerDir = "${config.qgroget.server.containerDir}/authentik";
  authentikImage = "ghcr.io/goauthentik/server";
  authentikTag = "2025.6";

  # Common environment variables for authentik containers
  authentikEnv = {
    AUTHENTIK_REDIS__HOST = "redis";
    AUTHENTIK_POSTGRESQL__HOST = "postgresql";
    AUTHENTIK_POSTGRESQL__USER = "authentik";
    AUTHENTIK_POSTGRESQL__NAME = "authentik";
  };

  # Common volumes for authentik containers
  authentikVolumes = [
    "${containerDir}/media:/media:Z"
    "${containerDir}/custom-templates:/templates:Z"
  ];

  # Common environment files
  authentikEnvFiles = [
    "${config.sops.secrets."server/authentik/authentik-env".path}"
    "${config.sops.secrets."server/authentik/postgresPassword".path}"
  ];

  # Common service config
  commonServiceConfig = {
    Restart = "unless-stopped";
  };

  inherit (config.virtualisation.quadlet) containers pods;
in {
  sops.secrets = {
    "server/authentik/authentik-env" = {};
    "server/authentik/postgresPassword" = {};
  };

  qgroget.services.auth = {
    name = "auth";
    url = "http://127.0.0.1:9000";
    type = "public";
    journalctl = true;
    unitName = "authentik.service";
  };

  virtualisation.quadlet = {
    pods.SSO = {
      autoStart = true;
      podConfig = {
        name = "authentik";
        publishPorts = ["9000:9000"];
      };
      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };

    containers = {
      postgresql = {
        autoStart = true;
        containerConfig = {
          image = "docker.io/library/postgres:16-alpine";
          pod = pods.SSO.ref;
          environments = {
            POSTGRES_USER = authentikEnv.AUTHENTIK_POSTGRESQL__USER;
            POSTGRES_DB = authentikEnv.AUTHENTIK_POSTGRESQL__NAME;
          };
          environmentFiles = [
            "${config.sops.secrets."server/authentik/postgresPassword".path}"
          ];
          volumes = ["${containerDir}/db:/var/lib/postgresql/data:Z"];
        };
        serviceConfig = commonServiceConfig;
      };

      redis = {
        autoStart = true;
        containerConfig = {
          image = "docker.io/library/redis:alpine";
          pod = pods.SSO.ref;
          exec = ["--save" "60" "1" "--loglevel" "warning" "--port" "6379"];
          volumes = ["${containerDir}/redis/data:/data:Z"];
          environmentFiles = [
            "${config.sops.secrets."server/authentik/authentik-env".path}"
          ];
        };
        serviceConfig = commonServiceConfig;
      };

      authentik = {
        autoStart = true;
        containerConfig = {
          image = "${authentikImage}:${authentikTag}";
          pod = pods.SSO.ref;
          exec = ["server"];
          environments = authentikEnv;
          volumes = authentikVolumes ++ ["${containerDir}/img:/img:Z"];
          environmentFiles = authentikEnvFiles;
        };
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [containers.postgresql.ref containers.redis.ref];
          After = [containers.postgresql.ref containers.redis.ref];
        };
      };

      authentik-worker = {
        autoStart = true;
        containerConfig = {
          image = "${authentikImage}:${authentikTag}";
          pod = pods.SSO.ref;
          exec = ["worker"];
          environments = authentikEnv;
          volumes = authentikVolumes;
          environmentFiles = authentikEnvFiles;
        };
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [containers.postgresql.ref containers.redis.ref];
          After = [containers.postgresql.ref containers.redis.ref];
        };
      };
    };
  };
}
