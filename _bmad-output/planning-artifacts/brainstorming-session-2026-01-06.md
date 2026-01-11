# Brainstorming Session Results

**Date:** 2026-01-06  
**Topic:** NixOS Server Service Module Architecture Refactoring  
**Techniques Used:** Morphological Analysis, Constraint Mapping, First Principles Thinking  

---

## Session Overview

**Goals:**
- Unified service declaration interface for all server services
- Enforced declarations for persistence and backups
- Global settings for enabling/disabling services
- Reduced boilerplate when adding new services
- Implementation-agnostic interface (container vs native)

---

## Key Decisions

### Architecture Choice: Service-Centric (Option A)

Each service owns its options under `qgroget.server.<serviceName>`, with a collector module aggregating enabled services into Traefik routes, persistence, backups, and database provisioning.

### Service Classification

| Category | Services | Pattern |
|----------|----------|---------|
| **Infrastructure** | Traefik | Consumes from services, doesn't follow service rules |
| **Core Services** | Authelia, LLDAP, DNS | Follow service rules with dependencies |
| **Application Services** | Jellyfin, Immich, Arrs, etc. | Follow service rules |
| **Databases** | PostgreSQL | Auto-provisioned based on service declarations |

### Parameter Decisions

| Parameter | Decision |
|-----------|----------|
| **URL generation** | Auto from `port` → `http://127.0.0.1:${port}` |
| **`persistedData`** | REQUIRED (no default, must be explicit even if `[]`) |
| **`backupDirectories`** | REQUIRED (no default, must be explicit even if `[]`) |
| **Container abstraction** | Interface-agnostic - services don't know if they're containers |
| **Non-exposed services** | Same interface with `exposed = false` |
| **Traefik** | Infrastructure consumer, receives config from services |
| **Databases** | Auto-provisioned from service `database` declarations |
| **Dependencies** | Declarable via `dependsOn` list |

---

## Final Service Contract

```nix
qgroget.server.<serviceName> = {
  # ═══════════════════════════════════════════════════════════
  # REQUIRED - Enforced declarations (no defaults)
  # ═══════════════════════════════════════════════════════════
  enable = lib.mkEnableOption "Enable <serviceName>";
  
  port = lib.mkOption {
    type = lib.types.int;
    description = "Internal port (URL auto-generated as http://127.0.0.1:port)";
  };
  
  persistedData = lib.mkOption {
    type = lib.types.listOf (lib.types.either lib.types.str persistedDirSubmodule);
    description = "Directories to persist (required, use [] for stateless)";
    # NO DEFAULT - forces explicit declaration
  };
  
  backupDirectories = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "Directories to backup (required, use [] for no backup)";
    # NO DEFAULT - forces explicit declaration
  };
  
  # ═══════════════════════════════════════════════════════════
  # OPTIONAL - With sensible defaults
  # ═══════════════════════════════════════════════════════════
  exposed = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Create Traefik route";
  };
  
  subdomain = lib.mkOption {
    type = lib.types.str;
    default = "<serviceName>";
    description = "Subdomain for Traefik routing";
  };
  
  type = lib.mkOption {
    type = lib.types.enum [ "private" "public" ];
    default = "private";
    description = "private = local network only, public = internet accessible";
  };
  
  middlewares = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = []; # Derived from type if empty
    description = "Traefik middlewares to apply";
  };
  
  dependsOn = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Other services this depends on (checked at eval time)";
  };
  
  database = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "Database for this service";
        type = lib.mkOption {
          type = lib.types.enum [ "postgresql" "sqlite" ];
          default = "postgresql";
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "<serviceName>";
          description = "Database name (auto-provisioned)";
        };
      };
    };
    default = { enable = false; };
  };
  
  # ═══════════════════════════════════════════════════════════
  # SERVICE-SPECIFIC - Extended per service module
  # ═══════════════════════════════════════════════════════════
  # Each service adds its own options (users, mediaPaths, etc.)
};
```

---

## Global Settings Structure

```nix
qgroget.server = {
  # Global configuration
  domain = "qgroget.fr";
  containerDir = "/persist/containers";
  
  defaults = {
    backupEnabled = true;      # Global backup toggle
    ssoEnabled = true;         # Global SSO toggle
    defaultType = "private";   # Default exposure type
  };
  
  # Per-service configurations
  jellyfin = { enable = true; ... };
  immich = { enable = true; ... };
  sonarr = { enable = true; ... };
  # etc.
};
```

---

## Collector Module (New)

A central `collector.nix` module that:

1. **Aggregates persistence** from all enabled services
2. **Aggregates backup paths** from all enabled services  
3. **Generates Traefik routes** for exposed services
4. **Auto-provisions PostgreSQL** databases based on service declarations
5. **Validates dependencies** (warns if `dependsOn` service not enabled)

### Pseudo-code

```nix
let
  enabledServices = lib.filterAttrs (name: cfg: cfg.enable) config.qgroget.server;
in {
  # 1. Aggregate persistence
  environment.persistence."/persist".directories = 
    lib.concatLists (lib.mapAttrsToList (n: c: c.persistedData) enabledServices);
  
  # 2. Aggregate backups
  qgroget.backups = lib.mapAttrs (name: cfg: {
    paths = cfg.backupDirectories;
  }) (lib.filterAttrs (n: c: c.backupDirectories != []) enabledServices);
  
  # 3. Generate Traefik config for exposed services
  services.traefik.dynamicConfigOptions.http = ...;
  
  # 4. Auto-provision PostgreSQL
  services.postgresql = {
    enable = lib.mkIf (hasPostgresServices) true;
    ensureDatabases = ...;
    ensureUsers = ...;
  };
}
```

---

## Proposed Module Structure

```
modules/server/
├── default.nix          # Imports all
├── options.nix          # Base service contract (submodule type)
├── collector.nix        # NEW: Aggregates persistence, backups, traefik, DBs
├── traefik/             # Infrastructure (receives config from collector)
├── media/
│   ├── video/           # jellyfin - follows contract
│   └── photo/           # immich - follows contract
├── arrs/                # follows contract
├── SSO/
│   ├── authelia/        # follows contract, dependsOn = ["lldap"]
│   └── lldap/           # follows contract
├── dns/                 # follows contract
├── backup/              # reads from qgroget.backups (populated by collector)
└── ...
```

---

## Migration Strategy (for PRD)

1. Create base service contract in `options.nix`
2. Create `collector.nix` module
3. Migrate one service (e.g., DNS - simple) as proof of concept
4. Migrate remaining services incrementally
5. Remove legacy `qgroget.services` usage once all migrated

---

## Next Steps

- **PRD**: Define functional and non-functional requirements
- **Architecture**: Detailed module interaction diagrams
- **Epics/Stories**: Break down into implementable units
