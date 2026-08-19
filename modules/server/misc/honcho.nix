{
  config,
  pkgs,
  ...
}: let
  honchoInitSql = pkgs.writeText "honcho-init.sql" ''
    CREATE EXTENSION IF NOT EXISTS vector;
  '';
in {
  sops.secrets."server/honcho/env" = {};

  systemd.tmpfiles.rules = [
    "d /opt/data/honcho 0755 root root -"
    "d /opt/data/honcho/db 0755 root root -"
    "d /opt/data/honcho/redis 0755 root root -"
  ];

  virtualisation.quadlet = {
    networks.honcho = {
      networkConfig = {};
    };

    containers.honcho-db = {
      autoStart = true;
      containerConfig = {
        name = "honcho-db";
        image = "docker.io/pgvector/pgvector:pg15";
        networks = ["honcho"];
        environments = {
          POSTGRES_DB = "postgres";
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_HOST_AUTH_METHOD = "trust";
          PGDATA = "/var/lib/postgresql/data/pgdata";
        };
        volumes = [
          "/opt/data/honcho/db:/var/lib/postgresql/data/pgdata:Z"
          "${honchoInitSql}:/docker-entrypoint-initdb.d/init.sql:Z"
        ];
        publishPorts = ["127.0.0.1:5432:5432"];
      };
      serviceConfig.Restart = "unless-stopped";
    };

    containers.honcho-redis = {
      autoStart = true;
      containerConfig = {
        name = "honcho-redis";
        image = "docker.io/redis:8.2";
        networks = ["honcho"];
        volumes = [
          "/opt/data/honcho/redis:/data:Z"
        ];
        publishPorts = ["127.0.0.1:6379:6379"];
      };
      serviceConfig.Restart = "unless-stopped";
    };

    containers.honcho-api = {
      autoStart = true;
      containerConfig = {
        name = "honcho-api";
        image = "ghcr.io/plastic-labs/honcho:latest";
        networks = ["honcho"];
        environmentFiles = [
          "${config.sops.secrets."server/honcho/env".path}"
        ];
        environments = {
          DB_CONNECTION_URI = "postgresql+psycopg://postgres:postgres@honcho-db:5432/postgres";
          CACHE_URL = "redis://honcho-redis:6379/0?suppress=true";
          CACHE_ENABLED = "true";
        };
        publishPorts = ["127.0.0.1:8000:8000"];
        # Overriding entrypoint
        podmanArgs = [
          "--entrypoint=[\"sh\",\"docker/entrypoint.sh\"]"
        ];
      };
      serviceConfig.Restart = "unless-stopped";
    };

    containers.honcho-deriver = {
      autoStart = true;
      containerConfig = {
        name = "honcho-deriver";
        image = "ghcr.io/plastic-labs/honcho:latest";
        networks = ["honcho"];
        environmentFiles = [
          "${config.sops.secrets."server/honcho/env".path}"
        ];
        environments = {
          DB_CONNECTION_URI = "postgresql+psycopg://postgres:postgres@honcho-db:5432/postgres";
          CACHE_URL = "redis://honcho-redis:6379/0?suppress=true";
          CACHE_ENABLED = "true";
        };
        podmanArgs = [
          "--entrypoint=[\"/app/.venv/bin/python\",\"-m\",\"src.deriver\"]"
        ];
      };
      serviceConfig.Restart = "unless-stopped";
    };
  };
}
