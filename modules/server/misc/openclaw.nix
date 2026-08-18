{
  config,
  pkgs,
  inputs,
  ...
}: {
  # OpenClaw is marked as insecure due to prompt injection risks
  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.6.33"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      openclawPackages = (inputs.openclaw.overlays.default final prev).openclawPackages;
    })
  ];

  # Define the SOPS secrets for OpenClaw
  sops.secrets."server/openclaw/gemini-api-key" = {
    owner = config.qgroget.user.username;
  };
  sops.secrets."server/openclaw/telegram-token" = {
    owner = config.qgroget.user.username;
  };
  sops.secrets."server/openclaw/gateway-token" = {
    owner = config.qgroget.user.username;
  };

  sops.secrets."server/openclaw/gog-password" = {
    owner = config.qgroget.user.username;
  };

  home-manager.users.${config.qgroget.user.username} = {
    imports = [inputs.openclaw.homeManagerModules.openclaw];

    home.packages = [
      pkgs.chromium
      pkgs.nss
      pkgs.gh
      pkgs.jq
      (pkgs.writeShellScriptBin "gog" ''
        export GOG_KEYRING_BACKEND=file
        export GOG_KEYRING_PASSWORD=$(cat ${config.sops.secrets."server/openclaw/gog-password".path})
        exec ${inputs.openclaw.inputs.nix-openclaw-tools.packages.${pkgs.system}.gogcli}/bin/gog "$@"
      '')
      (pkgs.writeShellScriptBin "gogcli" ''
        export GOG_KEYRING_BACKEND=file
        export GOG_KEYRING_PASSWORD=$(cat ${config.sops.secrets."server/openclaw/gog-password".path})
        exec ${inputs.openclaw.inputs.nix-openclaw-tools.packages.${pkgs.system}.gogcli}/bin/gog "$@"
      '')
    ];

    programs.openclaw = {
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
              "https://openclaw.${config.qgroget.server.domain}"
            ];
          };
        };
        secrets = {
          providers = {
            local = {
              source = "file";
              path = config.sops.secrets."server/openclaw/gateway-token".path;
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
              id = "assistant";
              default = true;
              description = "Tu es mon assistant principal et ma secrétaire personnelle. Ton rôle est d'organiser mes idées, de me répondre de façon claire, et surtout d'orchestrer et de déléguer les tâches aux autres agents quand c'est nécessaire. N'hésite pas à faire appel à eux.";
              identity = {
                name = "Claw";
                emoji = "👩‍💼";
              };
              tools = {
                allow = ["*"];
              };
              skills = ["*"];
            }
            {
              id = "coder";
              model = {
                primary = "google/gemini-3.1-pro-preview";
              };
              description = "Expert software engineer, efficient and precise.";
              identity = {
                name = "Coder";
                emoji = "💻";
              };
              tools = {
                allow = ["*"];
              };
              skills = ["*"];
            }
            {
              id = "cleaner";
              model = {
                primary = "google/gemini-3.5-flash-lite";
              };
              workspace = "/home/strange/.openclaw/workspace/cleaner";
              description = "Mailbox cleaner, focused on sorting emails, deleting spam, and organizing the inbox.";
              identity = {
                name = "Cleaner";
                emoji = "🧹";
                theme = "emerald";
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
            tokenFile = config.sops.secrets."server/openclaw/telegram-token".path;
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
        stateDir = "/home/${config.qgroget.user.username}/.openclaw";
        workspaceDir = "/home/${config.qgroget.user.username}/.openclaw/workspace";
        environment = {
          GEMINI_API_KEY = config.sops.secrets."server/openclaw/gemini-api-key".path;
          PATH = "${pkgs.chromium}/bin:/run/current-system/sw/bin:/home/${config.qgroget.user.username}/.nix-profile/bin";
        };
      };
    };

    systemd.user.services.openclaw-gateway = {
      Install.WantedBy = ["default.target"];
      Service = {
        # Inject the GitHub token for gh cli
        ExecStartPre = [
          "${pkgs.bash}/bin/bash -c 'echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" > %t/openclaw-env'"
        ];
        EnvironmentFile = ["-%t/openclaw-env"];

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

  qgroget.services.openclaw = {
    subdomain = "openclaw";
    url = "http://127.0.0.1:18789";
    type = "private";
  };
}
