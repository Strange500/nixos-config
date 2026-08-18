{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Hermes is marked as insecure due to prompt injection risks
  nixpkgs.config.permittedInsecurePackages = [
    "hermes-2026.6.33"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      hermesPackages = (inputs.hermes.overlays.default final prev).hermesPackages;
    })
  ];

  # Define the SOPS secrets for Hermes
  sops.secrets."server/hermes/gemini-api-key" = {
    owner = config.qgroget.user.username;
  };
  sops.secrets."server/hermes/telegram-token" = {
    owner = config.qgroget.user.username;
  };
  sops.secrets."server/hermes/gateway-token" = {
    owner = config.qgroget.user.username;
  };

  sops.secrets."server/hermes/gog-password" = {
    owner = config.qgroget.user.username;
  };

  home-manager.users.${config.qgroget.user.username} = {
    imports = [inputs.hermes.homeManagerModules.hermes];

    home.packages = [
      pkgs.chromium
      pkgs.nss
      pkgs.gh
      pkgs.jq
      (pkgs.writeShellScriptBin "gog" ''
        export GOG_KEYRING_BACKEND=file
        export GOG_KEYRING_PASSWORD=$(cat ${config.sops.secrets."server/hermes/gog-password".path})
        exec ${inputs.hermes.inputs.nix-hermes-tools.packages.${pkgs.system}.gogcli}/bin/gog "$@"
      '')
      (pkgs.writeShellScriptBin "gogcli" ''
        export GOG_KEYRING_BACKEND=file
        export GOG_KEYRING_PASSWORD=$(cat ${config.sops.secrets."server/hermes/gog-password".path})
        exec ${inputs.hermes.inputs.nix-hermes-tools.packages.${pkgs.system}.gogcli}/bin/gog "$@"
      '')
    ];

    programs.hermes = {
      enable = true;

      config = {
        browser = {
          executablePath = "${pkgs.chromium}/bin/chromium";
        };
        gateway = {
          auth = {
            token = {
              source = "file";
              id = "value";
              provider = "local";
            };
          };
          controlUi = {
            allowedOrigins = [
              "https://hermes.${config.qgroget.server.domain}"
            ];
          };
        };
        secrets = {
          providers = {
            local = {
              source = "file";
              path = config.sops.secrets."server/hermes/gateway-token".path;
              mode = "singleValue";
            };
          };
        };
        plugins = {
          entries = {
            browser = {
              enabled = true;
            };
            google = {
              enabled = true;
              config = {
                webSearch = {
                  model = "google/gemini-3.5-flash";
                };
              };
            };
            github = {
              enabled = true;
            };
            firecrawl = {
              enabled = true;
            };
          };
        };
        agents = {
          defaults = {
            model = {
              primary = "google/gemini-3.5-flash-lite";
            };
            contextTokens = 80000;
            compaction = {
              mode = "safeguard";
              reserveTokensFloor = 24000;
              memoryFlush = {
                enabled = true;
              };
            };
            memorySearch = {
              experimental = {
                sessionMemory = true;
              };
              sources = ["memory" "sessions"];
            };
            heartbeat = {
              model = "google/gemini-2.5-flash-lite";
            };
          };
          list = [
            {
              id = "chiron";
              default = true;
              description = "Tu es mon assistant principal et ma secrétaire personnelle. Ton rôle est d'organiser mes idées, de me répondre de façon claire, et surtout d'orchestrer et de déléguer les tâches aux autres agents quand c'est nécessaire. N'hésite pas à faire appel à eux.";
              identity = {
                name = "Chiron";
                emoji = "👩‍💼";
              };
              tools = {
                allow = ["*"];
              };
              skills = ["*"];
            }
            {
              id = "prometheus";
              model = {
                primary = "google/gemini-3.1-pro-preview";
              };
              description = "Expert software engineer, efficient and precise.";
              identity = {
                name = "Prometheus";
                emoji = "💻";
              };
              tools = {
                allow = ["*"];
              };
              skills = ["*"];
            }
            {
              id = "hygieia";
              model = {
                primary = "google/gemini-3.5-flash-lite";
              };
              workspace = "/home/strange/.hermes/workspace/hygieia";
              description = "Mailbox cleaner, focused on sorting emails, deleting spam, and organizing the inbox.";
              identity = {
                name = "Hygieia";
                emoji = "🧹";
                theme = "emerald";
              };
              tools = {
                allow = ["*"];
              };
              skills = ["*"];
            }
            {
              id = "hephaestus";
              model = {
                primary = "google/gemini-3.5-flash";
              };
              description = "Ingénieur rapide et habile. Parfait pour les scripts d'automatisation, les tâches de code de difficulté moyenne et les itérations rapides.";
              identity = {
                name = "Hephaestus";
                emoji = "🛠️";
              };
              tools = {
                allow = ["*"];
              };
              skills = ["*"];
            }
          ];
        };
        channels = {
          telegram = {
            enabled = true;
            tokenFile = config.sops.secrets."server/hermes/telegram-token".path;
            dmPolicy = "pairing";
            groups = {
              "*" = {
                requireMention = true;
              };
            };
          };
        };
      };

      instances.default = {
        enable = true;
        stateDir = "/home/${config.qgroget.user.username}/.hermes";
        workspaceDir = "/home/${config.qgroget.user.username}/.hermes/workspace";
        environment = {
          GEMINI_API_KEY = config.sops.secrets."server/hermes/gemini-api-key".path;
          PATH = "${pkgs.chromium}/bin:/run/current-system/sw/bin:/home/${config.qgroget.user.username}/.nix-profile/bin";
        };
      };
    };

    systemd.user.services.hermes-gateway = {
      Install.WantedBy = ["default.target"];
      Service = {
        # Inject the GitHub token for gh cli
        ExecStartPre = [
          "${pkgs.bash}/bin/bash -c 'echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" > %t/hermes-env'"
        ];
        EnvironmentFile = ["-%t/hermes-env"];

        # Empêche l'élévation de privilèges (rend sudo/su inopérants)
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;

        # Autorise l'accès à la config et SSH pour git push, mais bloque strictement les outils d'élévation
        InaccessiblePaths = [
          "-/run/wrappers/bin/sudo"
          "-/run/wrappers/bin/su"
          "-/run/wrappers/bin/doas"
        ];
      };
    };
  };

  qgroget.services.hermes = {
    subdomain = "hermes";
    url = "http://127.0.0.1:18789";
    type = "private";
  };
}
