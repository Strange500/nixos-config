{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.qgroget.server.seerr;
in {
  options.qgroget.server.seerr = {
    enable = mkEnableOption "Custom Seerr setup with persistent config and Traefik integration";

    port = mkOption {
      type = types.port;
      default = 5055;
      description = "Internal port for Seerr web UI.";
    };
  };

  config = mkIf cfg.enable {
    services.seerr.configDir = "/var/lib/seerr";

    systemd.tmpfiles.rules = [
      "d ${config.services.seerr.configDir} 0755 seerr seerr -"
      "d ${config.services.seerr.configDir}/db 0755 seerr seerr -"
      "d ${config.services.seerr.configDir}/logs 0755 seerr seerr -"
      "Z ${config.services.seerr.configDir} - seerr seerr -"
    ];

    qgroget.services = {
      seerr = {
        subdomain = "seerr";
        url = "http://127.0.0.1:${toString config.services.seerr.port}";
        type = "public";
        journalctl = true;
        unitName = "seerr.service";
        persistedData = [
          "/var/lib/seerr"
        ];
        backupDirectories = [
          "/var/lib/seerr"
        ];
      };
    };

    users.users.seerr = {
      isSystemUser = true;
      description = "Seerr user";
      group = "seerr";
    };
    users.groups.seerr = {
    };

    services.seerr = {
      openFirewall = false;
      enable = true;
      port = cfg.port;
    };

    systemd.services.seerr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "seerr";
      Group = "seerr";
      StateDirectory = lib.mkForce [];
      ReadWritePaths = ["/var/lib/seerr"];
    };
  };
}
