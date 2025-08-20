{
  config,
  lib,
  ...
}: let
  authelia = "authelia-qgroget";
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/${authelia}/assets 0700 ${authelia} ${authelia} - -"
    "d /var/lib/${authelia}logs 0700 ${authelia} ${authelia} - -"
    "d /var/lib/${authelia}/database 0700 ${authelia} ${authelia} - -"
    "d /var/lib/${authelia}/users 0700 ${authelia} ${authelia} - -"
    "Z /var/lib/${authelia} 0700 ${authelia} ${authelia} - -"
  ];

  sops.secrets = {
    "server/authelia/smtp/password" = {
      owner = authelia;
      group = authelia;
    };
    "server/authelia/storage-encryption-key" = {
      owner = authelia;
      group = authelia;
    };
    "server/authelia/jwt-secret" = {
      owner = authelia;
      group = authelia;
    };
  };

  services.authelia.instances.qgroget = {
    enable = true;
    user = "${authelia}";
    group = "${authelia}";

    settings = {
      theme = "auto";

      server = {
        address = "tcp://0.0.0.0:9091";
        asset_path = "/var/lib/${authelia}/assets";
        endpoints = {
          authz = {
            forward-auth = {
              implementation = "ForwardAuth";
            };
          };
        };
      };

      log = {
        level = "info";
        format = "json";
        file_path = "/var/lib/${authelia}/logs/authelia.log";
        keep_stdout = true;
      };

      telemetry.metrics.enabled = false;

      webauthn = {
        disable = false;
        enable_passkey_login = true;
        display_name = "QGRoget";
        attestation_conveyance_preference = "indirect";
        timeout = "60s";
      };

      identity_validation.reset_password = {
        jwt_lifespan = "5m";
        jwt_algorithm = "HS256";
      };

      authentication_backend = {
        refresh_interval = "5m";
        password_change.disable = true;
        password_reset.disable = true;

        file = {
          path = "/var/lib/${authelia}/users_database.yml";
          watch = true;
          search = {
            email = true;
            case_insensitive = false;
          };
          password = {
            algorithm = "argon2";
            argon2 = {
              variant = "argon2id";
              iterations = 3;
              memory = 65536;
              parallelism = 4;
              key_length = 32;
              salt_length = 16;
            };
          };
        };
      };

      access_control.rules = [
        {
          domain = "*.${config.qgroget.server.domain}";
          policy = "two_factor";
        }
      ];

      session = {
        cookies = [
          {
            name = "authelia_session";
            domain = "qgroget.com";
            authelia_url = "https://auth.${config.qgroget.server.domain}";
            default_redirection_url = "https://unraid.${config.qgroget.server.domain}/";
            same_site = "lax";
            inactivity = "5m";
            expiration = "1h";
            remember_me = "1M";
          }
        ];
      };

      regulation = {
        modes = ["user"];
        max_retries = 3;
        find_time = "2m";
        ban_time = "5m";
      };

      storage = {
        local.path = "/var/lib/${authelia}/database.sqlite3";
      };

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submission://smtp.gmail.com:587";
          timeout = "5s";
          username = "qgroget@gmail.com";
          sender = "Authelia <qgroget@gmail.com>";
        };
      };
    };
    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets."server/authelia/smtp/password".path;
    };
    secrets = {
      jwtSecretFile = config.sops.secrets."server/authelia/jwt-secret".path;
      storageEncryptionKeyFile = config.sops.secrets."server/authelia/storage-encryption-key".path;
    };
  };

  qgroget.services.auth = {
    name = "auth";
    url = "http://127.0.0.1:9091";
    type = "public";
  };

  services.traefik.dynamicConfigOptions.http.middlewares.SSO = {
    forwardAuth = {
      address = "http://127.0.0.1:9091/api/authz/forward-auth";
      trustForwardHeader = true;
      authResponseHeaders = [
        "Remote-User"
        "Remote-Groups"
        "Remote-Email"
        "Remote-Name"
      ];
    };
  };
}
