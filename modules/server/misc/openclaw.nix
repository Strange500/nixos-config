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

  home-manager.users.${config.qgroget.user.username} = {
    imports = [inputs.openclaw.homeManagerModules.openclaw];

    home.packages = [pkgs.chromium pkgs.nss];

    programs.openclaw = {
      enable = true;

      config = {
        gateway = {
          auth = {
            token = "server-6-local-gateway-token-xyz";
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
}
