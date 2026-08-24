{
  config,
  lib,
  pkgs,
  ...
}: let
  traefikLib = import ../../../lib/traefik.nix {inherit lib;};

  services = config.qgroget.services;

  mergedTraefikConfig =
    lib.foldl'
    lib.recursiveUpdate
    {}
    (map (svc: svc.traefikDynamicConfig) (lib.attrValues services));
  tomlFmt = pkgs.formats.toml {};
  traefikDynamicConfigFile = tomlFmt.generate "traefik-dynamic.toml" mergedTraefikConfig;
in {
  config = {
    systemd.services.qgroget.serviceConfig.WorkingDirectory = "/var/lib/traefik";

    systemd.tmpfiles.rules = [
      "d /plugins-storage 0755 traefik traefik -"
      "d /var/lib/traefik 0700 traefik traefik -"
      "d /var/lib/traefik/dynamic 2770 traefik traefik-users -"
      "Z /var/lib/traefik/dynamic 2770 traefik traefik-users -"
    ];

    # Rootless users declare their own Traefik routes via Home Manager (written
    # to /var/lib/traefik/dynamic/<username>.toml). The `traefik-users` group
    # gates write access to that directory (mode 2770, setgid so newly created
    # files stay in the group); Traefik reads them through the `users` file
    # provider below.
    users.groups.traefik-users = {};
    users.users.traefik.extraGroups = ["traefik-users"];
    users.users.${config.qgroget.user.username}.extraGroups = ["traefik-users"];

    sops = {
      secrets."server/traefik/clientCaCert" = {
        owner = "traefik";
        group = "traefik";
      };
    };

    qgroget.services = {
      proxy = {
        subdomain = "proxy";
        url = "http://127.0.0.1:8080";
        type = "private";
        persistedData = [
          {
            directory = "${config.services.traefik.dataDir}";
            user = "traefik";
            group = "traefik";
            mode = "u=rwx,g=rx,o=";
          }
        ];
      };
    };

    systemd.services.traefik.preStart = ''
      mkdir -p /run/traefik/secureConf
      conf=$(cat ${traefikDynamicConfigFile})
      # cat > /run/traefik/secureConf/traefik-dynamic.toml <<EOF
      # ${traefikDynamicConfigFile}
      # EOF
      echo "$conf" > /run/traefik/secureConf/traefik-dynamic.toml
    '';

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

        # System dynamic config (regenerated at each rebuild).
        providers.file = {
          filename = "";
          directory = "/run/traefik/secureConf";
          watch = true;
        };

        # User-declared routes (rootless, via Home Manager). Hot-reloaded on
        # change thanks to `watch`, without rebuild nor restart of Traefik.
        providers.users.file = {
          directory = "/var/lib/traefik/dynamic";
          watch = true;
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
    };

    qgroget.services.proxy.traefikDynamicConfig = let
      dynamicHttp = traefikLib.mkDynamicHttp {
        domain = config.qgroget.server.domain;
        testEnable = config.qgroget.server.test.enable;
        services = config.qgroget.services;
      };
    in {
      http = dynamicHttp // {
        middlewares = dynamicHttp.middlewares // {
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

    networking.firewall = {
      allowedTCPPorts = [80 443] ++ lib.optional (config.qgroget.server.test.enable) [8080];
      allowedUDPPorts = [443];
    };
  };
}
