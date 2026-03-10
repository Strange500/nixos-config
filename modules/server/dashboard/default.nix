{
  config,
  lib,
  pkgs,
  ...
}: let
  icons = {
    jellyfin = "sh-jellyfin";
    adguardhome = "sh-adguard-home";
    lldap = "sh-lldap";
    obsidian = "sh-obsidian";
    prowlarr = "sh-prowlarr";
    radarr = "sh-radarr";
    sonarr = "sh-sonarr";
    radarr-anime = "sh-radarr";
    sonarr-anime = "sh-sonarr";
    qui = "sh-qui";
    vaultwarden = "sh-vaultwarden";
    dashy = "sh-dashy";
    immich = "sh-immich";
    jellyseerr = "sh-jellyseerr";
    n8n = "sh-n8n";
    proxy = "sh-traefik";
  };

  yamlFormat = pkgs.formats.yaml {};

  dashyConf = {
    pageInfo = {
      title = "QGroget";
      description = "Services hub for QGroget";
      logo = "https://file.qgroget.com/img/server_branding/logo.png";
    };

    appConfig = {
      statusCheck = false;
      theme = "minimal-dark";
      fontAwesomeKey = "c94dc2b452";
      layout = "vertical";
      iconSize = "small";
      auth = {
        enableOidc = true;
        oidc = {
          clientId = "qq3zKTOsDqjPEQ2Ey7sTXFA3o7my0FBFrDI9CUFoExR1DIqZtJVWUYorw2GzJXKDuiCKIRjs";
          endpoint = "https://auth.${config.qgroget.server.domain}";
          adminGroup = "admin";
          scope = "openid profile email groups";
        };
      };
    };

    sections = [
      {
        name = "Today";
        icon = "far fa-smile-beam";
        displayData = {
          collapsed = false;
          hideForGuests = false;
        };
        widgets = [
          {
            type = "embed";
            options = {
              html = "<p align=\"center\"><iframe src=\"https://lldap.${config.qgroget.server.domain}\" frameborder='0' style=\"width: 540px; height: 615px; overflow: hidden;\"></iframe></p>";
            };
          }
        ];
      }
      {
        name = "Services";
        icon = "far fa-briefcase";
        items =
          lib.mapAttrsToList (
            name: service: let
              accessGroup =
                if name == "immich"
                then "immich"
                else if service.type == "private"
                then "admin"
                else "users";
            in {
              title = name;
              url = "https://${
                if service.subdomain != ""
                then service.subdomain + "."
                else ""
              }${config.qgroget.server.domain}";
              icon = icons.${name} or "far fa-question-circle";

              displayData = {
                showForKeycloakUsers = {
                  groups = [accessGroup];
                  roles = [accessGroup];
                };
              };

              statusCheck = true;
            }
          )
          config.qgroget.services;
      }
    ];
  };

  dashConfYml = yamlFormat.generate "dashy.yml" dashyConf;
in {
  qgroget.services = {
    top = {
      subdomain = "top";
      url = "http://127.0.0.1:61208";
      type = "private";
    };
  };

  qgroget.services.dashy.traefikDynamicConfig = {
    http.middlewares.dashy = {
      headers = {
        accessControlAllowMethods = ["GET" "OPTIONS" "PUT"];
        accessControlAllowOriginList = [
          "*"
        ];
        accessControlMaxAge = 100;
        addVaryHeader = true;
      };
    };
  };

  services.glances = {
    enable = true;
    port = 61208;
  };

  virtualisation.quadlet = {
    containers = {
      dashy = {
        autoStart = true;
        containerConfig = {
          name = "dashy";
          image = "lissy93/dashy:latest";
          publishPorts = [
            "2659:8080"
          ];
          volumes = [
            "${dashConfYml}:/app/user-data/conf.yml"
          ];
          environments = {
            NODE_ENV = "production";
          };
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };

  qgroget.services.dashy = {
    subdomain = "";
    url = "http://127.0.0.1:2659";
    type = "public";
    middlewares = ["dashy"];
  };

  services.authelia.instances.qgroget.settings = {
    identity_providers.oidc = {
      claims_policies = {
        dashy = {
          id_token = [
            "email"
            "email_verified"
            "alt_emails"
            "preferred_username"
            "name"
          ];
        };
      };
      clients = [
        {
          client_id = "qq3zKTOsDqjPEQ2Ey7sTXFA3o7my0FBFrDI9CUFoExR1DIqZtJVWUYorw2GzJXKDuiCKIRjs";
          client_name = "dashy";
          public = true;
          authorization_policy = "dashy";
          claims_policy = "dashy";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "https://${config.qgroget.server.domain}"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          grant_types = [
            "authorization_code"
          ];
          response_types = [
            "code"
          ];
          consent_mode = "implicit";
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "none";
        }
      ];
      cors.allowed_origins = [
        "https://${config.qgroget.server.domain}"
      ];
      authorization_policies = {
        dashy = {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = [
                "group:users"
              ];
            }
          ];
        };
      };
    };
  };
}
