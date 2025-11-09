{lib, ...}: {
  options.qgroget = {
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Service name for subdomain";
          };
          url = lib.mkOption {
            type = lib.types.str;
            description = "Backend URL";
          };
          type = lib.mkOption {
            type = lib.types.enum ["private" "public"];
            default = "private";
            description = "either 'private' or 'public'. 'private' means that the service is only accessible from the local network, while 'public' means it is accessible from the internet.";
          };
          persistedData = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of paths to persist for the service.";
          };
          backupDirectories = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of directories to include in backups for the service.";
          };
          middlewares = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of middlewares to apply to the service.";
          };
          logPath = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Path to the log file for the service.";
          };
          journalctl = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "If true, the service will be logged using journalctl.";
          };
          unitName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "The name of the systemd unit for the service, used for journalctl filtering.";
          };
          traefikDynamicConfig = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Additional Traefik dynamic configuration for the service.";
          };
        };
      });
      default = {};
      description = "QGroget services to be managed";
    };
  };
}
