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

    programs.openclaw = {
      enable = true;

      # Inject secrets via environment paths (OpenClaw reads the file contents)
      environment = {
        GEMINI_API_KEY = config.sops.secrets."server/openclaw/gemini-api-key".path;
      };

      config = {
        agents = {
          defaults = {
            model = {
              primary = "google/gemini-3.1-pro-preview";
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
        stateDir = "~/.openclaw";
        workspaceDir = "~/.openclaw/workspace";
      };
    };
  };
}
