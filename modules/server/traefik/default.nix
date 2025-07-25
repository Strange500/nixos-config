{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.persistence."/persist".directories = [
    "${config.services.traefik.dataDir}"
  ];

  services.traefik = {
    enable = true;

    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      log = {
        level = "INFO";
        filePath = "${config.services.traefik.dataDir}/traefik.log";
        format = "json";
      };

      accesslog = {
        format = "common";
        filePath = "${config.services.traefik.dataDir}/access.log";
        bufferingSize = 50;
      };

      api = {
        dashboard = true;
        insecure = true;
      };

      entryPoints = {
        web = {
          address = ":80";
          http = {
            redirections = {
              entryPoint = {
                to = "websecure";
                scheme = "https";
              };
            };
          };
          transport = {
            respondingTimeouts = {
              readTimeout = 0;
            };
          };
        };

        websecure = {
          address = ":443";
          http = {
            middlewares = [
              "googlenoindex"
            ];
          };
          transport = {
            respondingTimeouts = {
              readTimeout = 0;
            };
          };
        };
      };

      certificatesResolvers = {
        staging = {
          acme = {
            email = "qgroget@gmail.com";
            storage = "${config.services.traefik.dataDir}/acme.json";
            caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
            httpChallenge = {
              entryPoint = "web";
            };
          };
        };

        production = {
          acme = {
            email = "qgroget@gmail.com";
            storage = "${config.services.traefik.dataDir}/acme.json";
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            httpChallenge = {
              entryPoint = "web";
            };
          };
        };
      };

      serversTransport = {
        insecureSkipVerify = true;
      };
    };

    dynamicConfigOptions = {
      http = {
        middlewares = {
          authentik = {
            forwardAuth = {
              address = "http://authentik:9000/outpost.goauthentik.io/auth/traefik";
              trustForwardHeader = true;
              authResponseHeaders = [
                "X-authentik-username"
                "X-authentik-groups"
                "X-authentik-email"
                "X-authentik-name"
                "X-authentik-uid"
                "X-authentik-jwt"
                "X-authentik-meta-jwks"
                "X-authentik-meta-outpost"
                "X-authentik-meta-provider"
                "X-authentik-meta-app"
                "X-authentik-meta-version"
              ];
            };
          };

          googlenoindex = {
            headers = {
              customResponseHeaders = {
                X-Robots-Tag = "noindex";
              };
            };
          };
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [80 443 8080];
  };
}
