{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.qgroget.server.calibre-importer;
  grimmoryCfg = config.qgroget.server.grimmory;
in {
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.users.${cfg.user} = {
        isSystemUser = true;
        uid = 972;
        group = cfg.group;
        description = "Calibre auto-importer user";
      };
      users.groups.${cfg.group} = {};

      # Ensure state directory is created with correct permissions
      systemd.tmpfiles.rules = [
        "d ${cfg.libraryDir} 0775 ${cfg.user} ${cfg.group} -"
      ];

      virtualisation.quadlet.containers.calibre = {
        autoStart = true;
        containerConfig = {
          name = "calibre-web-automated";
          image = "docker.io/crocodilestick/calibre-web-automated:latest";
          environments = {
            PUID = "972";
            PGID = "973";
            TZ = "Europe/Paris";
          };
          volumes = [
            "${config.qgroget.server.containerDir}/calibre/config:/config:Z"
            "${cfg.libraryDir}:/calibre-library:Z"
            "${cfg.sourceDir}/ingest:/cwa-book-ingest:Z"
          ];
          publishPorts = ["8083:8083"];
        };
      };

      qgroget.services.calibre = {
        subdomain = "calibre";
        url = "http://127.0.0.1:8083";
        type = "private";
        middlewares = ["SSO"];
      };

      services.authelia.instances.qgroget.settings.access_control.rules = lib.mkAfter [
        {
          domain = "calibre.${config.qgroget.server.domain}";
          policy = "two_factor";
          subject = ["group:admin"];
        }
      ];
    })

    (lib.mkIf grimmoryCfg.enable {
      systemd.tmpfiles.rules = [
        "d ${config.qgroget.server.containerDir}/grimmory/data 0775 ${cfg.user} ${cfg.group} -"
        "d ${config.qgroget.server.containerDir}/grimmory/bookdrop 0775 ${cfg.user} ${cfg.group} -"
        "d ${config.qgroget.server.containerDir}/grimmory/mariadb 0775 ${cfg.user} ${cfg.group} -"
      ];

      virtualisation.quadlet.pods.grimmory-pod = {
        podConfig.publishPorts = ["6060:6060"];
      };

      virtualisation.quadlet.containers.mariadb = {
        autoStart = true;
        containerConfig = {
          name = "mariadb";
          image = "lscr.io/linuxserver/mariadb:11.4.8";
          pod = "grimmory-pod.pod";
          environments = {
            PUID = "972";
            PGID = "973";
            TZ = "Europe/Paris";
            MYSQL_ROOT_PASSWORD = "super_secure_password";
            MYSQL_DATABASE = "grimmory";
            MYSQL_USER = "grimmory";
            MYSQL_PASSWORD = "your_secure_password";
          };
          volumes = [
            "${config.qgroget.server.containerDir}/grimmory/mariadb:/config:Z"
          ];
        };
      };

      virtualisation.quadlet.containers.grimmory = {
        autoStart = true;
        containerConfig = {
          name = "grimmory";
          image = "docker.io/grimmory/grimmory:latest";
          pod = "grimmory-pod.pod";
          environments = {
            USER_ID = "972";
            GROUP_ID = "973";
            TZ = "Europe/Paris";
            DATABASE_URL = "jdbc:mariadb://127.0.0.1:3306/grimmory";
            DATABASE_USERNAME = "grimmory";
            DATABASE_PASSWORD = "your_secure_password";
            SWAGGER_ENABLED = "false";
            FORCE_DISABLE_OIDC = "false";
          };
          volumes = [
            "${config.qgroget.server.containerDir}/grimmory/data:/app/data:Z"
            "/mnt/data/media/media/books:/books:Z"
            "${config.qgroget.server.containerDir}/grimmory/bookdrop:/bookdrop:Z"
          ];
        };
      };

      qgroget.services.grimmory = {
        subdomain = "grimmory";
        url = "http://127.0.0.1:6060";
        type = "public";
      };

      services.authelia.instances.qgroget.settings.access_control.rules = lib.mkAfter [
        {
          domain = "grimmory.${config.qgroget.server.domain}";
          policy = "two_factor";
          subject = ["group:admin"];
        }
      ];
    })
  ];
}
