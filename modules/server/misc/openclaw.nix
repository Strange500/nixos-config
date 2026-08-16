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

  # Define the SOPS secret for OpenClaw's environment variables
  sops.secrets."server/openclaw/env" = {
    owner = config.qgroget.user.username;
  };

  home-manager.users.${config.qgroget.user.username} = {
    imports = [inputs.openclaw.homeManagerModules.openclaw];

    programs.openclaw = {
      enable = true;
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
            dmPolicy = "pairing";
            groups = {
              "*" = {
                requireMention = true;
              };
            };
          };
        };
      };
    };

    # Run OpenClaw as a background service
    systemd.user.services.openclaw = {
      Unit = {
        Description = "OpenClaw Gateway";
        After = ["network-online.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };
      Service = {
        ExecStart = "${pkgs.openclawPackages.openclaw}/bin/openclaw gateway";
        Restart = "always";
        RestartSec = "10s";
        EnvironmentFile = [
          config.sops.secrets."server/openclaw/env".path
        ];
      };
    };
  };
}
