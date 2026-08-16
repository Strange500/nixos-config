{
  config,
  inputs,
  ...
}: {
  # Define the SOPS secret for OpenClaw's environment variables
  sops.secrets."server/openclaw/env" = {
    owner = config.qgroget.user.username;
  };

  home-manager.users.${config.qgroget.user.username} = {
    imports = [inputs.openclaw.homeManagerModules.default];

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
