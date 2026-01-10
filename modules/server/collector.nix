{
  config,
  lib,
  ...
}: {
  # Collector Module for Service Aggregation
  #
  # This module automatically aggregates configurations from all enabled services
  # defined in qgroget.serviceModules.*. It provides:
  # - Persistence path aggregation for Impermanence
  # - Backup directory aggregation for Restic/Borg
  # - Traefik dynamic configuration generation
  # - Database provisioning declarations
  # - Evaluation-time validation (port conflicts, dependencies, etc.)

  config = {
    # Persistence Path Aggregation (Story 2.1)
    # Aggregates dataDir and backupPaths from all enabled services
    # CRITICAL: Uses lib.mkAfter to merge with existing host persistence config
    environment.persistence."/persist".directories = let
      enabledServices = lib.filterAttrs (name: service: service.enable) config.qgroget.serviceModules;
      persistencePaths = lib.flatten (lib.mapAttrsToList (
          name: service:
            [service.dataDir] ++ service.backupPaths
        )
        enabledServices);
      uniquePaths = lib.unique persistencePaths;
    in
      lib.mkAfter uniquePaths;

    # Backup Directory Aggregation (Story 2.2)
    # Aggregates backup configurations from all enabled services with backupPaths
    qgroget.backups = let
      enabledServices = lib.filterAttrs (name: service: service.enable) config.qgroget.serviceModules;
      servicesWithBackups = lib.filterAttrs (name: service: service.backupPaths != []) enabledServices;
    in
      lib.mapAttrs (name: service: {
        paths = lib.unique ([service.dataDir] ++ service.backupPaths);
        systemdUnits = ["${name}.service"];
        priority = 100;
        exclude = [];
        preBackup = null;
        postBackup = null;
      })
      servicesWithBackups;

    # Traefik Routing Generation (Story 2.3)
    # Automatically generates Traefik routers and services from enabled service contracts
    # Maps service types to appropriate middleware chains
    qgroget.traefik = let
      enabledServices = lib.filterAttrs (name: service: service.enable) config.qgroget.serviceModules;
      exposedServices = lib.filterAttrs (name: service: service.exposed) enabledServices;

      # Type to middleware mapping for automatic middleware chain assignment
      typeToMiddleware = {
        public = []; # Public: no authentication required
        private = ["authentik"]; # Private: authentication via Authentik
        admin = ["authentik" "rate-limit"]; # Admin: authentication + rate limiting
        internal = []; # Internal: local network only
      };

      # Generate router configuration for a service
      generateRouter = name: service: {
        rule = "Host(`${service.subdomain}.${service.domain}`)";
        service = "service-${name}";
        middlewares = lib.unique (
          (typeToMiddleware.${service.type} or ["authentik"])
          ++ service.middleware
        );
        entryPoints = ["websecure"];
        tls = {
          certResolver = "production";
        };
      };

      # Generate service backend configuration
      generateService = name: service: {
        loadBalancer = {
          servers = [
            {url = "http://localhost:${toString service.port}";}
          ];
        };
      };
    in {
      routers = lib.mapAttrs generateRouter exposedServices;
      services = lib.mapAttrs generateService exposedServices;
    };

    # TODO: Add other aggregations (databases, validation) in future stories
  };
}
