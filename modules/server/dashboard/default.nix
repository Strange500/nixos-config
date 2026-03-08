{
  config,
  lib,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};

  dashyConf = {
    pageInfo = {
      title = "Hello, Alicia";
      description = "General browser startpage";
      logo = "https://i.ibb.co/71WyyzM/little-bot-3.png";
    };

    appConfig = {
      statusCheck = false;
      theme = "charry-blossom";
      fontAwesomeKey = "c94dc2b452";
      customCss = ".clock p.time { font-size: 3rem !important; }";
      layout = "vertical";
      iconSize = "small";
      auth = {
        enableOidc = true;
        oidc = {
          clientId = "qq3zKTOsDqjPEQ2Ey7sTXFA3o7my0FBFrDI9CUFoExR1DIqZtJVWUYorw2GzJXKDuiCKIRjs";
          endpoint = "https://auth.${config.qgroget.server.domain}";
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          adminGroup = "admin";
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
          {type = "clock";}
          {
            type = "weather";
            options = {
              apiKey = "efdbade728b37086877a5e83442004db";
              city = "London";
            };
          }
          {
            type = "crypto-watch-list";
            options = {
              currency = "GBP";
              sortBy = "marketCap";
              assets = [
                "bitcoin"
                "ethereum"
                "monero"
                "solana"
                "polkadot"
              ];
            };
          }
        ];
      }
      {
        name = "Productivity";
        icon = "far fa-briefcase";
        items = [
          {
            title = "ProtonMail";
            icon = "favicon";
            url = "https://mail.protonmail.com/";
            description = "Primary email account";
            tags = ["hosted" "personal" "email" "mail"];
            hotkey = 1;
          }
          {
            title = "CTemplar";
            icon = "favicon";
            url = "https://mail.ctemplar.com/";
            description = "Secondary email account";
            tags = ["hosted" "personal" "email" "mail"];
            hotkey = 2;
          }
          {
            title = "AnonAddy";
            icon = "favicon";
            url = "https://app.anonaddy.com/";
            description = "Mail alias forwarder";
            tags = ["hosted" "personal" "forwarder" "aliases" "email"];
            hotkey = 3;
            statusCheckAcceptCodes = "401";
          }
          {
            title = "LessPass";
            icon = "favicon";
            url = "https://lesspass.com/";
            description = "Deterministic password generator";
            tags = ["hosted" "personal" "password" "generate" "deterministic"];
            hotkey = 4;
          }
          {
            title = "EteSync";
            icon = "favicon";
            url = "https://pim.etesync.com/";
            description = "Calendar + Contacts, CalDAV sync";
            tags = ["hosted" "personal" "caldav" "calendar" "contacts" "tasks" "planning"];
            hotkey = 5;
          }
          {
            title = "Tasks";
            icon = "https://i.ibb.co/v4jznK0/todo-list.png";
            url = "https://pim.etesync.com/pim/tasks";
            description = "Todo list and tasks from CalDAV";
            tags = ["hosted" "personal" "caldav" "tasks" "planning"];
            hotkey = 6;
          }
          {
            title = "Tresorit";
            icon = "favicon";
            url = "https://web.tresorit.com/";
            description = "Off-site encrypted file sync + backup";
            tags = ["hosted" "personal" "files" "backup" "sync" "storage"];
            hotkey = 7;
          }
          {
            title = "StandardNotes";
            icon = "favicon";
            url = "https://app.standardnotes.com/";
            description = "Notes, and my second brain";
            tags = ["hosted" "personal" "notes"];
            hotkey = 8;
          }
          {
            title = "1Password";
            icon = "favicon";
            url = "https://my.1password.com/";
            description = "Password Manager";
            tags = ["hosted" "personal" "passwords"];
            hotkey = 9;
          }
        ];
      }
      {
        name = "Dev & Cloud";
        icon = "far fa-code";
        items = [
          {
            title = "GitHub";
            icon = "favicon";
            url = "https://github.com/";
          }
          {
            title = "StackOverflow";
            icon = "favicon";
            url = "http://stackoverflow.com/";
          }
          {
            title = "CloudFlare";
            icon = "favicon";
            url = "https://dash.cloudflare.com/";
            statusCheckAcceptCodes = "403";
          }
          {
            title = "DigitalOcean";
            icon = "favicon";
            url = "https://cloud.digitalocean.com/";
          }
          {
            title = "Netlify";
            icon = "favicon";
            url = "https://app.netlify.com/";
          }
          {
            title = "CodeSandbox";
            icon = "favicon";
            url = "https://codesandbox.io/dashboard";
          }
          {
            title = "Hack the Box";
            icon = "favicon";
            url = "https://www.hackthebox.com/home";
          }
          {
            title = "Documentation";
            subItems = [
              {
                title = "JavaScript";
                url = "https://developer.mozilla.org";
                icon = "si-javascript";
                color = "#F7DF1E";
              }
              {
                title = "TypeScript";
                url = "https://www.typescriptlang.org/docs";
                icon = "si-typescript";
                color = "#3178C6";
              }
              {
                title = "Svelt";
                url = "https://svelte.dev/docs";
                icon = "si-svelte";
                color = "#FF3E00";
              }
              {
                title = "Go";
                url = "https://go.dev/doc";
                icon = "si-go";
                color = "#00ADD8";
              }
              {
                title = "Rust";
                url = "https://doc.rust-lang.org/reference";
                icon = "si-rust";
                color = "#000000";
              }
              {
                title = "Docker";
                url = "https://docs.docker.com/";
                icon = "si-docker";
                color = "#2496ED";
              }
            ];
          }
        ];
      }
      {
        name = "Social & News";
        icon = "far fa-thumbs-up";
        items = [
          {
            title = "Discord";
            icon = "si-discord";
            url = "https://discord.com/channels/";
          }
          {
            title = "Mastodon";
            icon = "si-mastodon";
            url = "https://mastodon.social/";
          }
          {
            title = "Reddit";
            icon = "si-reddit";
            url = "https://www.reddit.com/";
          }
          {
            title = "HackerNews";
            icon = "si-ycombinator";
            url = "https://news.ycombinator.com/";
          }
          {
            title = "Twitter";
            icon = "si-twitter";
            url = "https://twitter.com/";
          }
          {
            title = "YouTube";
            icon = "si-youtube";
            url = "https://youtube.com/";
          }
          {
            title = "Instagram";
            icon = "si-instagram";
            url = "https://www.instagram.com/";
          }
          {
            title = "News";
            icon = "si-bbc";
            url = "https://bbc.co.uk/news";
          }
          {
            title = "Crypto Prices";
            icon = "fab fa-bitcoin";
            url = "https://www.livecoinwatch.com/";
            description = "Real-time crypto prices and read-only portfolio";
            provider = "Live Coin Watch";
          }
        ];
      }
    ];
  };

  dashConfYml = yamlFormat.generate "dashy.yml" dashyConf;
in {
  qgroget.services = {
    top = {
      name = "top";
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
    name = "shit";
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
            "roles"
            "email"
            "groups"
          ];
          grant_types = [
            "authorization_code"
          ];
          response_types = [
            "code"
          ];
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
              policy = "two_factor";
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
