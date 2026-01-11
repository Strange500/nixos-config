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
          ++ service.middlewares
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

    # Database Provisioning (Story 2.4)
    # Automatically provisions PostgreSQL databases based on service declarations
    # Creates databases, users, and exposes connection details back to services
    services.postgresql = let
      enabledServices = lib.filterAttrs (name: service: service.enable) config.qgroget.serviceModules;
      allDatabases = lib.flatten (lib.mapAttrsToList (
          name: service:
            map (db:
              {
                inherit name;
                serviceName = name;
              }
              // db)
            service.databases
        )
        enabledServices);

      # Filter PostgreSQL databases
      postgresqlDatabases = lib.filter (db: db.type == "postgresql") allDatabases;

      # Validation: Check for required fields
      validateDatabase = db: let
        missingFields = lib.filter (field: !(lib.hasAttr field db) || db.${field} == null || db.${field} == "") ["type" "name" "user"];
      in
        if missingFields != []
        then
          throw ''
            Service '${db.serviceName}' declares database with missing required fields: ${lib.concatStringsSep ", " missingFields}

            All PostgreSQL databases require: type, name, user

            Example:
              databases = [{
                type = "postgresql";
                name = "immich";
                user = "immich";
              }];
          ''
        else db;

      # Validate database names (PostgreSQL naming rules)
      validateDatabaseName = db: let
        nameRegex = "^[a-zA-Z_][a-zA-Z0-9_]*$";
        isValidName = builtins.match nameRegex db.name != null;
        isValidLength = builtins.stringLength db.name <= 63;
      in
        if !isValidName
        then
          throw ''
            Service '${db.serviceName}' declares invalid database name '${db.name}'

            Database names must:
            - Start with a letter or underscore
            - Contain only letters, numbers, and underscores
            - Be 63 characters or less

            Example:
              databases = [{
                type = "postgresql";
                name = "immich_db";
                user = "immich";
              }];
          ''
        else if !isValidLength
        then
          throw ''
            Service '${db.serviceName}' declares database name '${db.name}' that is too long (${toString (builtins.stringLength db.name)} characters)

            Database names must be 63 characters or less.

            Example:
              databases = [{
                type = "postgresql";
                name = "immich";
                user = "immich";
              }];
          ''
        else db;

      # Apply validations
      validatedDatabases = map (db: validateDatabaseName (validateDatabase db)) postgresqlDatabases;

      # Check for duplicate database names
      databaseNames = map (db: db.name) validatedDatabases;
      uniqueDatabaseNames = lib.unique databaseNames;
    in
      lib.mkIf (postgresqlDatabases != []) {
        enable = true;
        ensureDatabases = uniqueDatabaseNames;
        ensureUsers =
          map (db: {
            name = db.user;
          })
          validatedDatabases;
      };

    # Database Connection Configuration (Story 2.4)
    # Exposes structured database connection details back to service modules
    # Services can access via config.qgroget.databases.postgresql.<serviceName>
    qgroget.databases.postgresql = let
      enabledServices = lib.filterAttrs (name: service: service.enable) config.qgroget.serviceModules;
      postgresqlDatabases = lib.flatten (lib.mapAttrsToList (
          name: service:
            map (db: {serviceName = name;} // db) (lib.filter (db: db.type == "postgresql") service.databases)
        )
        enabledServices);
    in
      lib.mapAttrs' (serviceName: service: {
        name = serviceName;
        value = map (db: {
          host = "localhost";
          port = 5432;
          database = db.name;
          user = db.user;
          # Password comes from SOPS secrets: server/<serviceName>/db_password
        }) (lib.filter (db: db.type == "postgresql") service.databases);
      })
      enabledServices;

    # TODO: Add other aggregations (databases, validation) in future stories
  };
}
