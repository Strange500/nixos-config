{
  config,
  lib,
  pkgs,
  ...
}:
# ============================================================================
# SERVICE MODULE TEMPLATE
# ============================================================================
#
# This is an annotated template demonstrating the THREE-SECTION SERVICE
# MODULE PATTERN for the NixOS service contract architecture.
#
# USAGE: Copy this file to create a new service module at:
#   modules/server/<category>/<service>/default.nix
#
# Example: For a new "backup-service", create:
#   modules/server/backup/backup-service/default.nix
#
# Then replace "_example" with your service name throughout this file.
#
# ============================================================================
# SECTION 1: SERVICE CONTRACT DECLARATION
# ============================================================================
#
# This section defines the service options that will be exposed through the
# qgroget.serviceModules.<service> interface. These options form the contract
# between this service module and the collector (modules/server/collector.nix).
#
# REQUIRED FIELDS (must always be explicitly provided by users):
#   - enable: Boolean to activate/deactivate the service
#   - domain: Domain name for routing (becomes subdomain in Traefik)
#   - dataDir: Base directory for all persistent service data
#
# OPTIONAL FIELDS (have sensible defaults, can be omitted):
#   - extraConfig: Service-specific configuration
#   - middleware: List of security/auth middleware names
#   - databases: List of database names required by this service
#   - backupPaths: Directories to include in automated backups
#
# The collector automatically discovers enabled services by reading this
# interface and aggregates their configurations for centralized management.
#
# ============================================================================
let
  cfg = config.qgroget.serviceModules._example;
in {
  # ========================================================================
  # PART 1A: SERVICE CONTRACT OPTIONS
  # ========================================================================
  #
  # Define all configuration options exposed by this service.
  # Users will configure via: qgroget.serviceModules._example.<option> = value;
  #
  options.qgroget.serviceModules._example = lib.mkOption {
    type = lib.types.submodule {
      options = {
        # ====================================================================
        # REQUIRED FIELDS - Must be provided by host configuration
        # ====================================================================

        enable = lib.mkOption {
          type = lib.types.bool;
          description = ''
            Enable the _example service.

            When enabled, the service will be started, configured, and
            automatically integrated with:
            - Traefik for HTTP routing
            - Backup system (if backupPaths provided)
            - Database provisioning (if databases specified)
          '';
          example = true;
        };

        domain = lib.mkOption {
          type = lib.types.str;
          description = ''
            Domain name for the service (used to generate subdomain).

            Example values:
              - "example.local" -> service accessible at example.example.local
              - "homelab" -> service accessible at example.homelab

            This domain is used by Traefik to route HTTP requests to the
            service. The collector converts this to proper routing rules.
          '';
          example = "example.local";
        };

        dataDir = lib.mkOption {
          type = lib.types.str;
          description = ''
            Base directory for all persistent service data.

            Example values:
              - "/var/lib/example-service"
              - "/mnt/data/services/example"
              - "/data/services/example"

            This directory will be:
            1. Created with proper permissions if it doesn't exist
            2. Mounted/accessible to the service
            3. Used as reference by backupPaths (can use relative paths)
            4. Persisted across system rebuilds (via impermanence or similar)

            NOTE: The preStart hook ensures this directory exists before
                  the service starts. Set proper ownership in preStart if needed.
          '';
          example = "/var/lib/example-service";
        };

        # ====================================================================
        # OPTIONAL FIELDS - Have sensible defaults, can be omitted
        # ====================================================================

        extraConfig = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = ''
            Additional service-specific configuration (service-defined).

            Use this for service-specific settings that don't fit the
            standard contract. The structure and content are entirely
            service-specific.

            Example usage in the service implementation:
              cfg.extraConfig.customOption = true;
              cfg.extraConfig.logLevel = "debug";
          '';
          example = {
            customSetting = "value";
            logLevel = "info";
          };
        };

        middleware = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = ''
            List of middleware names to apply to Traefik routes.

            Common middleware values:
              - "authentik": Requires authentication via Authentik
              - "chain-authelia": Requires authentication via Authelia
              - "rate-limit": Apply rate limiting

            Each middleware name must correspond to a Traefik middleware
            defined elsewhere in the system. The collector will validate
            that referenced middleware exists (future enhancement: story 3-3).

            Example with multiple middlewares:
              middleware = ["authentik" "rate-limit"];
          '';
          example = ["authentik"];
        };

        databases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = ''
            List of database names required by this service.

            IMPORTANT: Database names must be UNIQUE across all services.
            Use explicit names like "example_primary", "example_cache".
            Do NOT use generic names like "db" or "data".

            Examples:
              - databases = ["example_db"]; # Single database
              - databases = ["example_primary" "example_cache"]; # Multiple

            The collector will:
            1. Verify name uniqueness (future: story 2-4)
            2. Auto-provision PostgreSQL databases (future: story 2-4)
            3. Provide connection credentials via systemd LoadCredential

            How to use database credentials in implementation:
              - Credentials injected as: credentials.example_db_url
              - Connection URL format: postgresql://user:pass@localhost/dbname
          '';
          example = ["example_db"];
        };

        backupPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = ''
            List of paths to include in automated backups.

            Paths can be:
            - Absolute: "/var/lib/example-service/data"
            - Relative (to dataDir): "data", "config"

            Examples (assuming dataDir = "/var/lib/example-service"):
              backupPaths = [
                "data"              # Backs up /var/lib/example-service/data
                "config"            # Backs up /var/lib/example-service/config
                "/var/log/example"  # Also backs up external paths
              ];

            The collector aggregates all backupPaths across services and
            passes them to the backup system (e.g., restic).

            NOTE: Large directories should be planned carefully to avoid
                  excessive backup load. Consider excluding cache/temp via
                  backup system excludes.
          '';
          example = ["data" "config"];
        };
      };
    };
    default = {};
    description = "Configuration for the _example service using service contract pattern";
  };

  # ========================================================================
  # PART 1B: VALIDATION SECTION
  # ========================================================================
  #
  # Add assertions here to validate user configuration at evaluation time.
  # When a validation fails, the error message should include examples
  # of correct usage (see architecture NFR9).
  #
  config = lib.mkIf cfg.enable {
    # Example assertion - uncomment and customize for your service
    # assertions = [
    #   {
    #     assertion = cfg.domain != "";
    #     message = ''
    #       qgroget.serviceModules._example.domain must be set.
    #
    #       Example configuration:
    #         qgroget.serviceModules._example.domain = "example.local";
    #     '';
    #   }
    # ];
  };

  # ========================================================================
  # SECTION 2: IMPLEMENTATION SECTION
  # ========================================================================
  #
  # This section implements the actual service functionality. Choose the
  # appropriate pattern(s) for your service:
  #
  # OPTION A: systemd service (for native packages)
  # OPTION B: Container/Quadlet (for containerized services)
  # OPTION C: Both (show alternative implementations)
  #
  # This template shows both patterns. In practice, use only what applies
  # to your service.
  #
  # KEY PATTERNS:
  # 1. preStart: Creates directories, sets permissions, generates config
  # 2. LoadCredential: Injects secrets from sops-nix via systemd credentials
  # 3. Type: Usually "simple" or "oneshot"
  # 4. Restart: Usually "on-failure" for resilience
  # 5. Unit: Define After dependencies (e.g., postgresql.service)
  #
  # ========================================================================

  config = lib.mkIf cfg.enable {
    # ======================================================================
    # PATTERN A: systemd service (native package pattern)
    # ======================================================================
    #
    # Use this pattern when your service is a native NixOS package
    # (not containerized). Example: Jellyfin, Authelia, etc.
    #
    systemd.services._example = {
      description = "Example service (remove this and implement your service)";
      after = [
        "network-online.target"
        # Add PostgreSQL here if databases are used:
        # "postgresql.service"
      ];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      # preStart runs before the service starts - use for setup
      preStart = ''
        # Create data directory with proper permissions
        mkdir -p "${cfg.dataDir}"
        chmod 0755 "${cfg.dataDir}"

        # Create subdirectories if needed
        mkdir -p "${cfg.dataDir}/data"
        mkdir -p "${cfg.dataDir}/config"

        # Example: Set ownership (uncomment if needed)
        # chown -R example:example "${cfg.dataDir}"

        # Example: Generate configuration file from template
        # cat > "${cfg.dataDir}/config.yaml" << 'EOF'
        # domain: ${cfg.domain}
        # logLevel: info
        # EOF
      '';

      # Service configuration
      serviceConfig = {
        Type = "simple";
        # Replace with actual command for your service
        ExecStart = "${pkgs.example-package}/bin/example-service";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening (optional but recommended)
        PrivateTmp = true;
        NoNewPrivileges = true;

        # Use systemd credentials for secrets
        # This loads secrets defined in sops.secrets."services/_example/..."
        # and makes them available as $CREDENTIALS_DIRECTORY/secret_name
        LoadCredential = [
          # Example: "db_password:${config.sops.secrets."services/_example/db_password".path}"
        ];

        # Example environment variables
        Environment = [
          "EXAMPLE_DATA_DIR=${cfg.dataDir}"
          "EXAMPLE_DOMAIN=${cfg.domain}"
        ];

        # Process user/group (uncomment and set if needed)
        # User = "example";
        # Group = "example";

        # Log settings
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "_example";
      };

      # Override preStart for specific needs
      script = ''
        # This runs as the service user after preStart
        echo "Starting example service on domain: ${cfg.domain}"
      '';
    };

    # ======================================================================
    # PATTERN B: Container service (Quadlet pattern)
    # ======================================================================
    #
    # Use this pattern for containerized services. Quadlets are systemd
    # units that manage containers via podman/docker.
    #
    # This is an ALTERNATIVE to Pattern A - use one OR the other, not both.
    # Showing both in template for reference.
    #
    # Uncomment this section if using containers:
    #
    # virtualisation.quadlet.services._example = {
    #   # Quadlet options
    #   image = "example/example:latest";
    #   containerName = "_example";
    #   ports = ["8080:8080"];  # host:container
    #
    #   # Mount the data directory into container
    #   volumes = [
    #     "${cfg.dataDir}:/data:Z"  # :Z for SELinux context
    #   ];
    #
    #   # Environment variables
    #   environment = {
    #     EXAMPLE_DOMAIN = cfg.domain;
    #     EXAMPLE_DATA_DIR = "/data";
    #     LOG_LEVEL = "info";
    #   };
    #
    #   # Auto-restart
    #   autoStart = true;
    #   autoRestart = "on-failure";
    #
    #   # Systemd integration (depends on other services)
    #   unitConfig = {
    #     After = "network-online.target postgresql.service";
    #     Wants = "network-online.target";
    #   };
    #
    #   # Container resource limits (optional)
    #   # memory = "1G";
    #   # cpus = "1.0";
    # };

    # ======================================================================
    # Example: Create systemd service for the container (if using Pattern B)
    # ======================================================================
    #
    # If using Quadlet containers, you may need a systemd service wrapper:
    #
    # systemd.services._example = {
    #   description = "Example service (container)";
    #   after = ["podman.service"];
    #   requires = ["quadlet-_example.service"];
    #   wantedBy = ["multi-user.target"];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStart = "${pkgs.podman}/bin/podman start _example";
    #     ExecStop = "${pkgs.podman}/bin/podman stop _example";
    #   };
    # };
  };

  # ========================================================================
  # SECTION 3: SECRETS HANDLING SECTION
  # ========================================================================
  #
  # This section integrates with sops-nix for secure secret management.
  #
  # PATTERN:
  # 1. Define secrets in sops.secrets with sops-nix paths
  # 2. Use LoadCredential in systemd to inject them
  # 3. Access via $CREDENTIALS_DIRECTORY/secret_name in service
  #
  # EXAMPLE: If your service needs a database password:
  #   1. Add to secrets/secrets.yaml:
  #      services:
  #        _example:
  #          db_password: <encrypted-password-from-sops>
  #   2. Declare here:
  #      sops.secrets."services/_example/db_password" = {...}
  #   3. Load in systemd via LoadCredential
  #   4. Access in service startup script via $CREDENTIALS_DIRECTORY
  #
  # ========================================================================

  config = lib.mkIf cfg.enable {
    # Example secrets declaration - uncomment and customize
    # sops.secrets."services/_example/db_password" = {
    #   sopsFile = ../../../secrets/secrets.yaml;
    #   path = "/run/secrets/services-_example-db_password";
    #   owner = "example";
    #   group = "example";
    #   mode = "0400";
    # };

    # sops.secrets."services/_example/api_key" = {
    #   sopsFile = ../../../secrets/secrets.yaml;
    #   path = "/run/secrets/services-_example-api_key";
    #   owner = "example";
    #   group = "example";
    #   mode = "0400";
    # };

    # Use secrets in systemd service via LoadCredential:
    # serviceConfig.LoadCredential = [
    #   "db_password:${config.sops.secrets."services/_example/db_password".path}"
    #   "api_key:${config.sops.secrets."services/_example/api_key".path}"
    # ];

    # Then in the service script, read from:
    # source $CREDENTIALS_DIRECTORY/db_password
    # export DB_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/db_password)
  };

  # ========================================================================
  # SECTION 3B: USER/GROUP CREATION (if needed)
  # ========================================================================
  #
  # Some services run as dedicated system users. Create them here.
  #
  users = lib.mkIf cfg.enable {
    users._example = {
      isSystemUser = true;
      group = "_example";
      home = cfg.dataDir;
      shell = "${pkgs.nologin}/bin/nologin";
      createHome = false;
      description = "System user for _example service";
    };

    groups._example = {};
  };

  # ========================================================================
  # REFERENCE & DOCUMENTATION
  # ========================================================================
  #
  # For real implementations, see:
  # - Jellyfin service: modules/server/media/video/default.nix
  # - Service contract: modules/server/options.nix (qgroget.serviceModules)
  # - Architecture: _bmad-output/planning-artifacts/architecture.md
  #
  # Key decisions to make for YOUR service:
  #
  # 1. NATIVE OR CONTAINER?
  #    - Native: Use systemd.services (faster, smaller)
  #    - Container: Use virtualisation.quadlet (isolation, versioning)
  #    - This template shows both patterns
  #
  # 2. WHAT SECRETS ARE NEEDED?
  #    - Database password?
  #    - API keys?
  #    - TLS certificates?
  #    - Add to sops.secrets and LoadCredential
  #
  # 3. WHAT DIRECTORIES TO BACKUP?
  #    - Configuration: Usually yes
  #    - Data: Usually yes
  #    - Cache: Usually no (can be regenerated)
  #    - Logs: Usually no (usually not needed in restore)
  #
  # 4. WHAT MIDDLEWARE IS NEEDED?
  #    - Public service? Use "authentik" or "chain-authelia" for auth
  #    - Private service? Maybe just "rate-limit"
  #    - No auth? Leave middleware = []
  #
  # 5. CODE FORMATTING
  #    - After implementation, run: alejandra .
  #    - This auto-formats all Nix code to project standards
  #
  # ========================================================================
}
