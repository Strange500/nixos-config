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

    # TODO: Add other aggregations (backup paths, Traefik config, databases) in future stories
  };
}
