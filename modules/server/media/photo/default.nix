{config, ...}: let
  # Configuration constants
  cfg = {
    containerDir = "${config.qgroget.server.containerDir}/immich";
    uploadLocation = "/mnt/immich";
    port = 2283;
    podName = "immich";

    containers = {
      database = "immich_postgres";
      redis = "immich_redis";
      machineLearning = "immich_machine_learning";
      server = "immich_server";
    };
  };

  commonEnv = {
    POSTGRES_USER = "immich";
    POSTGRES_DB = "immich";
    UPLOAD_LOCATION = "/mnt/user/immich";
    IMMICH_VERSION = "release";
    DB_HOSTNAME = cfg.containers.database;
    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";
    REDIS_HOSTNAME = cfg.containers.redis;
  };

  envFiles = ["${config.sops.secrets."server/immich/env".path}"];

  commonServiceConfig = {
    Restart = "unless-stopped";
  };

  images = {
    postgres = "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
    redis = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:51d6c56749a4243096327e3fb964a48ed92254357108449cb6e23999c37773c5";
    machineLearning = "ghcr.io/immich-app/immich-machine-learning:release";
    server = "ghcr.io/immich-app/immich-server:release";
  };

  traefikConfig = {
    bufferLimits = 5000000000;
  };

  inherit (config.virtualisation.quadlet) containers pods;
in {
  sops.secrets."server/immich/env" = {};

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

  qgroget.services.immich = {
    name = "immich";
    url = "http://127.0.0.1:${toString cfg.port}";
    type = "public";
    middlewares = ["immich-limit"];
    journalctl = true;
    unitName = "immich-server.service";
  };

  virtualisation.quadlet = {
    pods.immich = {
      autoStart = true;
      podConfig = {
        name = cfg.podName;
        publishPorts = ["${toString cfg.port}:${toString cfg.port}"];
      };
      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };

    containers = {
      immich-database = {
        autoStart = true;
        containerConfig = {
          pod = pods.immich.ref;
          name = cfg.containers.database;
          image = images.postgres;
          environments = commonEnv;
          environmentFiles = envFiles;
          volumes = [
            "${cfg.containerDir}/pg:/var/lib/postgresql/data:Z"
          ];
        };
        serviceConfig = commonServiceConfig;
      };

      immich-redis = {
        autoStart = true;
        containerConfig = {
          name = cfg.containers.redis;
          pod = pods.immich.ref;
          image = images.redis;
        };
        serviceConfig = commonServiceConfig;
      };

      immich-machine-learning = {
        autoStart = true;
        containerConfig = {
          pod = pods.immich.ref;
          image = images.machineLearning;
          environments = commonEnv;
          environmentFiles = envFiles;
        };
        serviceConfig = commonServiceConfig;
      };

      immich-server = {
        autoStart = true;
        containerConfig = {
          pod = pods.immich.ref;
          image = images.server;
          volumes = [
            "${cfg.uploadLocation}:/usr/src/app/upload:Z"
          ];
          environments = commonEnv;
          environmentFiles = envFiles;
        };
        serviceConfig = commonServiceConfig;
        unitConfig = {
          Requires = [
            containers.immich-database.ref
            containers.immich-redis.ref
            containers.immich-machine-learning.ref
          ];
          After = [
            containers.immich-database.ref
            containers.immich-redis.ref
            containers.immich-machine-learning.ref
          ];
        };
      };
    };
  };
}
