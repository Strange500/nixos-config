{
  config,
  inputs,
  ...
}: {
  # OpenClaw is marked as insecure due to prompt injection risks
  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.6.33"
  ];

  nixpkgs.overlays = [inputs.openclaw.overlays.default];

  # Define the SOPS secret for OpenClaw's environment variables
  sops.secrets."server/openclaw/env" = {
    owner = config.qgroget.user.username;
  };

  home-manager.users.${config.qgroget.user.username} = {
    imports = [inputs.openclaw.homeManagerModules.openclaw];
    nixpkgs.overlays = [inputs.openclaw.overlays.default];

    programs.openclaw = {
      enable = true;
      # You can add declarative configuration here if needed:
      # config = { ... };
    };

    # Inject the environment file into the OpenClaw systemd user service
    systemd.user.services.openclaw = {
      Service.EnvironmentFile = [
        config.sops.secrets."server/openclaw/env".path
      ];
    };
  };
}
