{
  config,
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

    # Inject the environment file into the OpenClaw systemd user service
    systemd.user.services.openclaw = {
      Service.EnvironmentFile = [
        config.sops.secrets."server/openclaw/env".path
      ];
    };
  };
}
