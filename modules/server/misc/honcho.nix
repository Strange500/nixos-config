{
  config,
  pkgs,
  ...
}: let
  honchoInitSql = pkgs.writeText "honcho-init.sql" ''
    CREATE EXTENSION IF NOT EXISTS vector;
  '';
  honchoConfigToml = ./honcho-config.toml;
  inherit (config.virtualisation.quadlet) pods;
in {
  sops.secrets."server/honcho/env" = {};

  systemd.tmpfiles.rules = [
    "d /opt/data/honcho 0755 root root -"
    "d /opt/data/honcho/db 0755 root root -"
    "d /opt/data/honcho/redis 0755 root root -"
  ];

  virtualisation.quadlet = {
    pods.honcho = {
      autoStart = true;
      podConfig = {
        name = "honcho";
        publishPorts = [
          "127.0.0.1:5432:5432"
          "127.0.0.1:6379:6379"
          "127.0.0.1:8000:8000"
          "127.0.0.1:8642:8642"
        ];
      };
      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };

    containers.honcho-db = {
      autoStart = true;
      containerConfig = {
        name = "honcho-db";
        pod = pods.honcho.ref;
        image = "docker.io/pgvector/pgvector:pg15";
        environments = {
          POSTGRES_DB = "honcho";
          POSTGRES_USER = "honcho";
          POSTGRES_PASSWORD = "honcho";
          POSTGRES_HOST_AUTH_METHOD = "trust";
          PGDATA = "/var/lib/postgresql/data/pgdata";
        };
        volumes = [
          "/opt/data/honcho/db:/var/lib/postgresql/data/pgdata:Z"
          "${honchoInitSql}:/docker-entrypoint-initdb.d/init.sql:ro"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
      };
    };

    containers.honcho-redis = {
      autoStart = true;
      containerConfig = {
        name = "honcho-redis";
        pod = pods.honcho.ref;
        image = "docker.io/redis:8.2";
        volumes = [
          "/opt/data/honcho/redis:/data:Z"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
      };
    };

    containers.honcho-api = {
      autoStart = true;
      containerConfig = {
        name = "honcho-api";
        pod = pods.honcho.ref;
        image = "ghcr.io/plastic-labs/honcho:latest";
        environmentFiles = [
          "${config.sops.secrets."server/honcho/env".path}"
        ];
        environments = {
          DB_CONNECTION_URI = "postgresql+psycopg://honcho:honcho@127.0.0.1:5432/honcho";
          CACHE_URL = "redis://127.0.0.1:6379/0?suppress=true";
          CACHE_ENABLED = "true";
          LLM_OPENAI_BASE_URL = "https://openrouter.ai/api/v1";
        };
        podmanArgs = [
          "--entrypoint=[\"sh\",\"docker/entrypoint.sh\"]"
        ];
        volumes = [
          "${honchoConfigToml}:/app/config.toml:ro"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
      };
      unitConfig = {
        Requires = ["honcho-db.service" "honcho-redis.service"];
        After = ["honcho-db.service" "honcho-redis.service"];
      };
    };

    containers.honcho-deriver = {
      autoStart = true;
      containerConfig = {
        name = "honcho-deriver";
        pod = pods.honcho.ref;
        image = "ghcr.io/plastic-labs/honcho:latest";
        environmentFiles = [
          "${config.sops.secrets."server/honcho/env".path}"
        ];
        environments = {
          DB_CONNECTION_URI = "postgresql+psycopg://honcho:honcho@127.0.0.1:5432/honcho";
          CACHE_URL = "redis://127.0.0.1:6379/0?suppress=true";
          CACHE_ENABLED = "true";
          METRICS_ENABLED = "false";
          LLM_VLLM_BASE_URL = "https://openrouter.ai/api/v1";
          LLM_EMBEDDING_BASE_URL = "https://openrouter.ai/api/v1";
          LLM_EMBEDDING_MODEL = "openai/text-embedding-3-small";
        };
        podmanArgs = [
          "--entrypoint=[\"/app/.venv/bin/python\",\"-m\",\"src.deriver\"]"
        ];
        volumes = [
          "${honchoConfigToml}:/app/config.toml:ro"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
      };
      unitConfig = {
        Requires = ["honcho-db.service" "honcho-redis.service"];
        After = ["honcho-db.service" "honcho-redis.service"];
      };
    };
  };
}
