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
            type = lib.types.listOf (lib.types.either lib.types.str (
              lib.types.submodule {
                options = {
                  directory = lib.mkOption {
                    type = lib.types.str;
                    description = "The directory to persist.";
                  };
                  user = lib.mkOption {
                    type = lib.types.str;
                    default = "root";
                    description = "Owner of the directory.";
                  };
                  group = lib.mkOption {
                    type = lib.types.str;
                    default = "root";
                    description = "Group of the directory.";
                  };
                  mode = lib.mkOption {
                    type = lib.types.str;
                    default = "0755";
                    description = "Permissions mode (e.g. \"u=rwx,g=rx,o=\" or \"0750\").";
                  };
                };
              }
            ));

            default = [];
            example = lib.literalExpression ''
              [
                "/var/lib/my-service"
                "/var/cache/jellyfin"
                {
                  directory = "/var/lib/traefik";
                  user = "traefik";
                  group = "traefik";
                  mode = "u=rwx,g=rx,o=";
                }
              ]
            '';
            description = ''
              List of directories to persist. Can be either a string (simple path)
              or an attribute set with advanced ownership/permission options.
            '';
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
    backups = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Paths to include in this backup.";
          };
          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Patterns or paths to exclude (restic --exclude / --exclude-file).";
          };
          preBackup = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Script to run before the backup.";
          };
          postBackup = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Script to run after the backup.";
          };
          systemdUnits = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Units to stop while this backup runs.";
          };
          priority = lib.mkOption {
            type = lib.types.int;
            default = 1000;
            description = "Lower runs earlier in the coordinator chain.";
          };
          # Optional: require network for this backup (e.g., remote repos)
          requireNetwork = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "If true, add Wants/After=network-online.target to this backup.";
          };
        };
      });
      default = {};
      description = "Declarative restic backups keyed by service name.";
    };

    # Service Contract Pattern - Flat structure with required and optional fields
    # Used by collector.nix to aggregate service configurations
    serviceModules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          # Required fields - must be explicitly provided
          enable = lib.mkOption {
            type = lib.types.bool;
            description = "Whether to enable this service";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Domain name for the service (used for subdomain or routing)";
          };
          dataDir = lib.mkOption {
            type = lib.types.str;
            description = "Data directory path for persistent service data";
          };

          # Optional fields
          extraConfig = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Additional service-specific configuration attributes";
          };
          middleware = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of middleware names to apply (e.g., authentik, chain-authelia)";
          };
          databases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of database names required for this service (must be unique across all services)";
          };
          backupPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of paths to include in backups for this service";
          };
          exposed = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the service should be exposed via Traefik routing";
          };
          subdomain = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Subdomain for the service (e.g., 'jellyfin' for jellyfin.example.com)";
          };
          type = lib.mkOption {
            type = lib.types.enum ["public" "private" "admin" "internal"];
            default = "private";
            description = "Service type determines default middleware chain (public/private/admin/internal)";
          };
          port = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Port number the service listens on (for Traefik routing)";
          };
        };
      });
      default = {};
      description = "Service module contracts - flat structure for all managed services";
    };

    traefik = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Traefik routing configuration aggregated from enabled services";
    };
  };
}
