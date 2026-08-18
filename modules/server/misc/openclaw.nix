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
            token = "server-6-local-gateway-token-xyz";
          };
          controlUi = {
            allowedOrigins = [
              "https://openclaw.qgroget.com"
            ];
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
                  model = "gemini-3.1-flash-preview";
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
              primary = "google/gemini-3.1-flash-preview";
            };
            contextTokens = 80000;
            compaction = {
              mode = "safeguard";
              reserveTokensFloor = 24000;
            };
            heartbeat = {
              model = "google/gemini-3.1-flash-preview";
            };
          };
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

    # Ensure the gateway starts on boot
    systemd.user.services.openclaw-gateway.Install.WantedBy = ["default.target"];
  };

  qgroget.services.openclaw = {
    subdomain = "openclaw";
    url = "http://127.0.0.1:18789";
    type = "private";
  };
}
