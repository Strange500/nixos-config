{config, ...}: let
  authelia = "authelia-qgroget";
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/${authelia}logs 0700 ${authelia} ${authelia} - -"
    "Z /var/lib/${authelia} 0700 ${authelia} ${authelia} - -"
  ];

  environment.persistence."/persist".directories = [
    "/var/lib/${authelia}"
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
    "server/authelia/hmac_secret" = {
      owner = authelia;
      group = authelia;
    };
    "server/authelia/oidc_private_key" = {
      owner = authelia;
      group = authelia;
    };
    "server/authelia/users" = {
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
        address = "tcp://127.0.0.1:9091";
        asset_path = config.logo.autheliaAssetsPath;
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
          path = config.sops.secrets."server/authelia/users".path;
          watch = false;
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

      access_control = {
        default_policy = "deny";
      };

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
      oidcHmacSecretFile = config.sops.secrets."server/authelia/hmac_secret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."server/authelia/oidc_private_key".path;
    };

    settings.identity_providers.oidc = {
      jwks = [
        {
          key_id = "authelia";
          algorithm = "RS256";
          use = "sig";
          certificate_chain = ''
            -----BEGIN CERTIFICATE-----
            MIIDJDCCAgygAwIBAgIRAMdmhuNJrLaDZltuLRgZmDYwDQYJKoZIhvcNAQELBQAw
            MjERMA8GA1UEChMIQXV0aGVsaWExHTAbBgNVBAMTFGF1dGhlbGlhLmV4YW1wbGUu
            Y29tMB4XDTI1MDgyMTA2NTc0MVoXDTI2MDgyMTA2NTc0MVowMjERMA8GA1UEChMI
            QXV0aGVsaWExHTAbBgNVBAMTFGF1dGhlbGlhLmV4YW1wbGUuY29tMIIBIjANBgkq
            hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4zo2vyK4msyKwF9EmaenlyB5hm+VPdQZ
            DI3prz8KnT4J2f+zRE85YsAnj4nhXsBibK6aUKPrMlvCZ3KrmsGuUMUK3mE+Thr7
            T0PiqEH9oCGltgnc0CcRlVq+O1YREHhuMa5vUkR80sziNMbeSVszVayWDT85YZT9
            fg++qdqZL5we9zPJKg8DR/ZYcuXABWHSLMc8QUEijvIiSFU55mu2pQogYG5m1HEC
            auxIBY/zYzKf+O9Y4iwovUIyxQBX3dAU8E26dFF3s6uXuPABjW0gwtxBI+Hkd1I0
            muupmAVq2klkpM4QCX1YQXTZdJ0jifk2D7EsrhUvY6r8ccsotqM/RwIDAQABozUw
            MzAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDAYDVR0TAQH/
            BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAyEVs72c+jP1H803EokEoJRaak3rsFaJf
            W2k31LZWC5UB4w6DXU4CTnZNfbugCQFeP5DXgo4XpwkW2p61w9dc19UylrAEQJiF
            WlCZ2suB9gWSoClfWHrmyL6B6TDqZFslBzop0PLsQB/cJu9EJzHx0Dl7fl2uuawr
            hQjaPMMlf5/BrEDjW4mTHMz9SqaMUeR2IrV7J/GZtvavaJYAZO93l7V+kkvmiITO
            LDJPMMWYV0ttlD6A7b5FWkMeSqf0C6XMKmZ53xbFzGbcubwCxi+aY9R48YrJW6mo
            Z4FKOuYmGYErFuD2/LtCNYvERadXskC05bbw5ZlOgCptdJIk/O/EVw==
            -----END CERTIFICATE-----
          '';
        }
      ];
      enable_client_debug_messages = false;
      minimum_parameter_entropy = 8;
      enforce_pkce = "public_clients_only";
      enable_pkce_plain_challenge = false;
      enable_jwt_access_token_stateless_introspection = false;
      discovery_signed_response_alg = "none";
      discovery_signed_response_key_id = "";
      require_pushed_authorization_requests = false;
      lifespans = {
        access_token = "1h";
        authorize_code = "1m";
        id_token = "1h";
        refresh_token = "90m";
      };
      cors = {
        endpoints = [
          "authorization"
          "token"
          "revocation"
          "introspection"
        ];
        allowed_origins_from_client_redirect_uris = false;
      };
    };
  };

  qgroget.services.auth = {
    name = "auth";
    url = "http://127.0.0.1:9091";
    type = "public";
  };

  qgroget.services.auth.traefikDynamicConfig.http.middlewares.SSO = {
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
