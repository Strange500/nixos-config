{
  config,
  lib,
  ...
}: {
  # Configure permissions for vaultwarden service
  qgroget.server.permissions.services.vaultwarden = {
    user = "vaultwarden";
    group = "password-manager";
    directories = [
      {
        path = "${config.qgroget.server.containerDir}/vaultwarden";
        mode = "0700";
        type = "Z";
      }
    ];
    secrets = {
      "server/vaultwarden/config" = {};
      "server/vaultwarden/env" = {};
    };
  };

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

  qgroget.backups.vaultwarden = {
    paths = [
      "${config.qgroget.server.containerDir}/vaultwarden"
    ];
    systemdUnits = [
      "vaultwarden.service"
    ];
  };

  virtualisation.quadlet = {
    containers.vaultwarden = {
      autoStart = true;

      containerConfig = {
        image = "docker.io/vaultwarden/server:latest";
        user = "${toString config.users.users.vaultwarden.uid}:${toString config.users.groups.password-manager.gid}";

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
