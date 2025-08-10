{
  config,
  lib,
  ...
}: {
  qgroget.services = {
    vaultwarden = {
      name = "vaultwarden";
      url = "http://127.0.0.1:4743";
      type = "public";
      journalctl = true;
      unitName = "vaultwarden.service";
      # middlewares = ["password-manager-limit"];
    };
  };

  sops.secrets = {
    "server/vaultwarden/config" = {
    };
    "server/vaultwarden/env" = {
    };
  };

  virtualisation.quadlet = {
    containers.vaultwarden = {
      autoStart = true;

      containerConfig = {
        image = "docker.io/vaultwarden/server:latest";

        # Environment variables
        environments = {
          WEBSOCKET_ENABLED = "true";
          SIGNUPS_ALLOWED = "false"; # Disable signups
          INVITATIONS_ALLOWED = "false"; # Allow invitations
          LOG_FILE = "/data/bitwarden.log";
        };
        environmentFiles = lib.mkIf (config.qgroget.server.test.enable) [
          "${config.sops.secrets."server/vaultwarden/env".path}"
        ];

        # Volume mounts
        volumes = [
          "${config.qgroget.server.containerDir}/vaultwarden:/data:Z"
          "${config.sops.secrets."server/vaultwarden/config".path}:/data/config.json:Z"
        ];

        # Port mapping
        publishPorts = ["4743:80"];
      };

      serviceConfig = {
        Restart = "unless-stopped";
      };

      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };
  };
}
