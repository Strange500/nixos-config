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
  };

  generateService = service: {
    loadBalancer = {
      servers = [
        {url = "${service.url}";}
      ];
    };
  };
in {
  options.traefik.services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Service name for subdomain";
        };
        url = lib.mkOption {
          type = lib.types.str;
          description = "Backend URL";
        };
        type = lib.mkOption {
          type = lib.types.enum ["private" "public"];
          default = "private";
          description = "either 'private' or 'public'. 'private' means that the service is only accessible from the local network, while 'public' means it is accessible from the internet.";
        };
      };
    });
    default = {};
    description = "Traefik services configuration";
  };

  config = {
    environment.persistence."/persist".directories = [
      "${config.services.traefik.dataDir}"
    ];

    sops = {
      secrets."server/traefik/clientCaCert" = {
        owner = "traefik";
        group = "traefik";
      };
    };

    traefik.services = {
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
          routers = lib.mapAttrs (name: service: generateRouter service) config.traefik.services;
          services = lib.mapAttrs (name: service: generateService service) config.traefik.services;
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
    };
  };
}
