{
  config,
  lib,
  pkgs,
  ...
}: let
  generateRouter = service: {
    rule = "Host(`${service.name}.${config.qgroget.server.domain}`)";
    entryPoints = ["websecure"];
    service = service.name;
    tls = {
      certResolver =
        if config.qgroget.server.test.enable
        then "staging"
        else "production";
    };
    tls.options = lib.mkIf (service.type == "private") "mtls";
    middlewares = lib.optionalAttrs (service.middlewares != []) service.middlewares;
  };

  generateService = service: {
    loadBalancer = {
      servers = [
        {url = "${service.url}";}
      ];
    };
  };
in {
  config = {
    systemd.services.qgroget.serviceConfig.WorkingDirectory = "/var/lib/traefik";

    environment.persistence."/persist".directories = [
      "${config.services.traefik.dataDir}"
    ];

    systemd.tmpfiles.rules = [
      "d /plugins-storage 0755 traefik traefik -"
    ];

    sops = {
      secrets."server/traefik/clientCaCert" = {
        owner = "traefik";
        group = "traefik";
      };
    };

    qgroget.services = {
      proxy = {
        name = "proxy";
        url = "http://127.0.0.1:8080";
        type = "private";
      };
    };

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

        experimental = {
          plugins = {
            geoblock = {
              moduleName = "github.com/PascalMinder/geoblock";
              version = "v0.3.3";
            };
          };
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
                "geoblock-fr"
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
          routers = lib.mapAttrs (name: service: generateRouter service) config.qgroget.services;
          services = lib.mapAttrs (name: service: generateService service) config.qgroget.services;
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

            geoblock-fr = {
              plugin = {
                geoblock = {
                  silentStartUp = false;
                  allowLocalRequests = true;
                  logLocalRequests = false;
                  logAllowedRequests = false;
                  logApiRequests = true;
                  api = "https://get.geojs.io/v1/ip/country/{ip}";
                  apiTimeoutMs = 750;
                  cacheSize = 15;
                  forceMonthlyUpdate = true;
                  allowUnknownCountries = false;
                  unknownCountryApiResponse = "nil";
                  countries = ["FR"];
                };
              };
            };
          };
        };

        tls = {
          options = {
            mtls = {
              minVersion = "VersionTLS12";
              clientAuth = {
                CAFiles = [
                  "${config.sops.secrets."server/traefik/clientCaCert".path}"
                ];
                clientAuthType = "RequireAndVerifyClientCert";
              };
            };
          };
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [80 443] ++ lib.optional (config.qgroget.server.test.enable) 8080;
      allowedUDPPorts = [443];
    };
  };
}
