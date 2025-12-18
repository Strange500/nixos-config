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

  qgroget.backups.vaultwarden = {
    paths = [
      "${config.qgroget.server.containerDir}/vaultwarden"
    ];
    systemdUnits = [
      "vaultwarden.service"
    ];
  };

  environment.etc."tmpfiles.d/vaultwarden.conf".text = ''
    Z ${config.qgroget.server.containerDir}/vaultwarden 0700 vaultwarden password-manager -
  '';

  users.users.vaultwarden = {
    isSystemUser = true;
    description = "User for running vaultwarden";
    home = "/nonexistent";
    createHome = false;
    group = "password-manager";
  };
  users.groups.password-manager = {};

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
        user = "${toString config.users.users.vaultwarden.uid}:${toString config.users.groups.password-manager.gid}";

        # Environment variables
        environments = {
          WEBSOCKET_ENABLED = "true";
          SIGNUPS_ALLOWED = "false"; # Disable signups
          INVITATIONS_ALLOWED = "false"; # Allow invitations
          LOG_FILE = "/data/bitwarden.log";
        };

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
