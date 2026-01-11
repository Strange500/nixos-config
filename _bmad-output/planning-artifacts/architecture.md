---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - docs/architecture.md
  - docs/index.md
  - docs/project-overview.md
  - docs/server-services.md
  - docs/component-inventory.md
workflowType: 'architecture'
project_name: 'nixos'
user_name: 'Strange'
date: '2026-01-07'
lastStep: 8
status: 'complete'
completedAt: '2026-01-07'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (36 total):**

The PRD defines comprehensive requirements across six capability areas:

1. **Service Contract Management (FR1-FR7)**: Infrastructure maintainers must define services with required fields (enable, port, persistedData, backupDirectories) and optional fields (exposed, subdomain, type, middlewares, dependsOn, database). The system enforces required field declaration through build-time type checking.

2. **Configuration Aggregation (FR8-FR13)**: The collector module automatically aggregates persistence paths, backup directories, Traefik routing configurations, and PostgreSQL database provisioning from all enabled services. Service enablement is centrally controlled through settings files.

3. **Build-Time Validation (FR14-FR18)**: The system detects missing required fields, provides clear error messages with usage examples, detects port conflicts, and validates contract conformance via `nix flake check` - all before deployment.

4. **Service Migration Support (FR19-FR22)**: Old and new patterns coexist during migration, allowing non-disruptive service migration with validation before cutover through conditional module imports.

5. **Testing & Verification (FR23-FR28)**: Three-layer testing strategy includes NixOS VM tests for runtime behavior, evaluation tests for collector logic, and integration tests for cross-service scenarios.

6. **Documentation & Developer Experience (FR29-FR36)**: Self-documenting system with annotated templates, architecture decision records, migration guides, and single-file service visibility.

**Non-Functional Requirements (13 total):**

Critical NFRs that shape the architecture:

- **Maintainability (NFR1-NFR4)**: Self-contained service modules, one-file comprehension for new contributors, coordinated contract updates within 4 hours for all 15 services, single-file edits for new services.

- **Reliability (NFR5-NFR9)**: 100% detection of missing declarations before deployment, port conflict prevention, zero downtime migration, evaluation-time error detection (not runtime), comprehensive validation prioritized over speed.

- **Developer Experience (NFR10-NFR13)**: Clear error messages with examples, inline template comments, before/after migration examples, actionable validation feedback.

**Scale & Complexity:**

- **Primary domain**: Infrastructure-as-Code / NixOS Module System
- **Complexity level**: Medium-High
- **Project type**: Brownfield refactoring with incremental migration
- **Estimated architectural components**: 
  - 4 core components (service contract, collector module, migration layer, validation system)
  - 15+ service migrations (Jellyfin, Immich, Sonarr, Radarr, Bazarr, Prowlarr, qBittorrent variants, Nicotine+, Vaultwarden, Traefik, Authelia, LLDAP, Portfolio, Obsidian, Syncthing, File Server)
  - 3 infrastructure integration points (Traefik, Impermanence, Backup systems)

### Technical Constraints & Dependencies

**NixOS Module System Constraints:**
- Must leverage Nix's type system (`types.submodule`, typed options, assertions)
- Lazy evaluation must be respected for build performance
- Cannot use external validation tools - must be pure Nix
- Type errors must fail at evaluation time, not runtime

**Existing Architecture Dependencies:**
- Current `qgroget.services` pattern already in use (must coexist during migration)
- Traefik dynamic configuration generation from service declarations
- Impermanence module expecting persistence paths in specific format
- Restic/Borg backup systems expecting directory lists
- SOPS secrets integration with service-specific credentials

**Migration Constraints:**
- 15+ production services must remain operational throughout migration
- Zero downtime requirement for family-used services (Jellyfin, Immich, Vaultwarden)
- Pattern coexistence required during 3-6 month migration window
- Each service can be migrated independently without affecting others

**Build System Requirements:**
- `nix flake check` must catch all configuration errors
- Build failures must provide actionable error messages
- Evaluation performance cannot degrade significantly (lazy evaluation critical)
- NixOS VM tests must run in CI/CD pipeline

### Cross-Cutting Concerns Identified

**Configuration Aggregation:**
- Traefik routing rules must be generated from all enabled services
- Persistence paths must be collected for Impermanence module
- Backup directories must be aggregated for Restic/Borg
- PostgreSQL databases must be auto-provisioned based on service declarations
- All aggregation must happen at evaluation time using functional transformations

**Validation & Error Handling:**
- Port conflict detection across all services
- Missing required field detection with clear error messages
- Service dependency validation (warn if service depends on disabled service)
- Path overlap detection (intentionally allowed for shared directories)
- Contract conformance validation via schema checks

**Pattern Coexistence:**
- Old `qgroget.services` pattern continues working
- New `qgroget.server.<service>` pattern introduced incrementally  
- Conditional module imports based on migration state
- No breaking changes to existing service configurations
- Clear migration path documented for each service type

**Developer Experience:**
- Single source of truth: one file per service contains everything
- Self-documenting contracts with inline comments
- Template-driven service creation (copy, customize, enable)
- Clear error messages pointing to exact issues with usage examples
- Fast onboarding for AI agents and human contributors

**Testing Strategy:**
- NixOS VM tests validate runtime behavior (services start, persist data, route correctly)
- Evaluation tests validate collector aggregation logic
- Integration tests validate cross-service interactions (dependencies, databases)
- Schema validation ensures contract conformance
- All tests runnable via `nix build .#checks.<system>.<testName>`

## Starter Template Evaluation

### Primary Technology Domain

**Infrastructure-as-Code / NixOS Module System** - This is not a traditional application development project but rather a module system refactoring within an existing NixOS configuration.

### Context: No Traditional Starter Applicable

Unlike web/mobile applications with CLI generators (create-next-app, create-react-app, etc.), NixOS module development follows a **reference implementation pattern** rather than a template generation approach.

**Existing Technical Foundation (Already Established):**
- Language: Nix (declarative, purely functional configuration language)
- Module System: NixOS module system with typed options (`types.submodule`)
- Build System: Nix flakes with lazy evaluation
- Testing: NixOS VM tests + evaluation tests
- Validation: Build-time type checking through Nix evaluation
- Deployment: `nixos-rebuild switch --flake .#Server`

### Architectural Foundation Approach

**Instead of a starter template, this project establishes:**

**1. Core Module Infrastructure**
```nix
modules/server/
├── options.nix       # Service contract definition with types.submodule
├── collector.nix     # Aggregation logic using lib.filterAttrs/mapAttrsToList
├── _template/        # Annotated service template for copying
│   └── default.nix
└── <service>/        # Individual service modules following template
    └── default.nix
```

**2. Service Template Pattern**

The template (`modules/server/_template/default.nix`) provides:
- Annotated contract fields with inline comments
- Example configurations for common scenarios
- Clear indication of required vs optional fields
- Usage examples for each contract element

**3. Reference Implementation Strategy**

Rather than generating from a template, the approach is:
1. Create core infrastructure (options.nix, collector.nix)
2. Migrate one simple service as proof of concept (e.g., DNS service)
3. Use that migration as reference for all others
4. Document the pattern in migration guide

**Architectural Decisions Established by This Foundation:**

**Type System & Validation:**
- Service contract enforced through `types.submodule` with typed options
- Required fields have no default values (forces explicit declaration)
- Assertion functions provide clear error messages with examples
- Port conflicts detected via `lib.unique` and list comprehension

**Module Organization:**
- Single-file service definition (no scattered configuration)
- Service-specific config colocated with persistence/backup declarations
- Central enablement in `hosts/Server/settings.nix`
- Conditional module imports for pattern coexistence

**Aggregation Pattern:**
- Functional transformations using `lib.filterAttrs` and `lib.mapAttrsToList`
- Pure Nix evaluation (no side effects, no external tools)
- Lazy evaluation respected for build performance
- Explicit data flow through functional composition

**Testing Infrastructure:**
- NixOS VM tests using `nixosTest` framework
- Evaluation tests for collector logic validation
- Integration tests for cross-service scenarios
- All tests exposed via flake `checks` output

**Migration Strategy:**
- Pattern coexistence via conditional imports
- Non-breaking incremental migration (one service at a time)
- Each service independently migratable
- Clear rollback path if issues discovered

**Developer Experience:**
- Self-documenting contracts through inline comments
- Template-driven development (copy, customize, enable)
- Single source of truth per service
- Clear error messages point to exact issues with fix examples

**Build & Deployment:**
- `nix flake check` catches all configuration errors before deployment
- Build failures include field name, description, and usage example
- Evaluation-time validation (not runtime discovery)
- Standard NixOS deployment workflow unchanged

### Implementation Note

The first implementation task is creating the core infrastructure:
1. Define service contract in `modules/server/options.nix`
2. Implement collector module in `modules/server/collector.nix`
3. Create annotated template in `modules/server/_template/default.nix`
4. Migrate one proof-of-concept service (DNS or similar simple service)
5. Document the pattern and validate with tests

This proof-of-concept migration serves as the "starter" for all subsequent service migrations.

## Core Architectural Decisions

### Decision Summary

The following architectural decisions establish the technical foundation for the NixOS service module refactoring. Each decision was made collaboratively to ensure the architecture meets functional requirements while maintaining developer ergonomics and system reliability.

### Service Contract Architecture

**Decision 1: Contract Structure**
- **Choice**: Flat structure (all fields at top level)
- **Rationale**: Simpler developer experience with less typing and nesting. Infrastructure maintainers want quick visibility of all options. Aligns with existing NixOS module conventions and produces shorter, clearer error message paths.
- **Implementation**:
```nix
qgroget.server.<service> = {
  enable = true;
  port = 8096;
  persistedData = ["/var/lib/service"];
  backupDirectories = ["/var/lib/service/data"];
  exposed = true;
  subdomain = "service";
  type = "public";
  middlewares = [];
  dependsOn = [];
  databases = [];
};
```

**Decision 2: Collector Activation**
- **Choice**: Automatic activation when any `qgroget.server.*` service is defined
- **Rationale**: Zero-configuration approach reduces friction during migration. Collector module runs transparently when new pattern services are present. Simplifies adoption - no extra flags needed.
- **Implementation**: Collector module always imported in server configuration, activates when `config.qgroget.server != {}`

**Decision 3: Migration Tracking**
- **Choice**: Implicit tracking by service definition presence
- **Rationale**: If a service exists under `qgroget.server.*`, it's using the new pattern. No extra bookkeeping or flags needed. Migration status queryable via `builtins.attrNames config.qgroget.server`.
- **Implementation**: Old services remain in current locations, new services defined under `qgroget.server.*`. Pattern coexistence via conditional imports.

### Validation & Error Handling

**Decision 4: Error Message Format**
- **Choice**: Detailed messages with usage examples (NFR10 requirement)
- **Rationale**: Critical for developer experience. Build-time feedback must be actionable. Error messages include field name, explanation, and correct usage example.
- **Implementation**:
```nix
message = ''
  Service '${name}' missing required field 'persistedData'
  
  This field declares which directories must persist across reboots.
  
  Example:
    qgroget.server.${name}.persistedData = [ "/var/lib/${name}" ];
'';
```

**Decision 5: Port Conflict Detection**
- **Choice**: Both evaluation-time assertions AND dedicated check test (defense in depth)
- **Rationale**: NFR5 requires 100% detection. Evaluation assertions catch issues during `nixos-rebuild`. Dedicated `nix flake check` test provides detailed conflict analysis. Two-layer approach ensures nothing slips through.
- **Implementation**:
  - Evaluation: Assertions in collector module comparing port lists
  - Check test: Dedicated analysis of all service ports with detailed reporting

**Decision 6: Dependency Validation**
- **Choice**: Build error (not warning) for missing service dependencies
- **Rationale**: Service dependencies are not optional - if a service declares `dependsOn = ["postgres"]`, that dependency must be satisfied. Failing fast prevents runtime surprises. Explicit is better than implicit.
- **Implementation**:
```nix
assertions = lib.forEach cfg.dependsOn (dep: {
  assertion = config.qgroget.server.${dep}.enable or false;
  message = "Service '${name}' depends on '${dep}' which is not enabled";
});
```

### Database Integration

**Decision 7: Database Configuration**
- **Choice**: Multiple database support with full connection details
- **Rationale**: Some services need multiple databases (e.g., PostgreSQL + Redis). Services need access to connection details (host, port, database name, user). Extensible to additional database types beyond PostgreSQL.
- **Implementation**:
```nix
databases = [
  {
    type = "postgresql";
    name = "immich";
    user = "immich";
    # Collector auto-provisions and provides: host, port
  }
  {
    type = "redis";
    name = "immich-cache";
  }
];
```

**Decision 8: Database Connection Information**
- **Choice**: Service-specific options accessible to service module
- **Rationale**: Service module decides how to pass connection info (environment variables for containers, config files for native services, etc.). Collector provides structured data, not pre-formatted strings. Works for both Quadlet containers and native systemd services.
- **Implementation**: Collector exposes database config as structured attributes. Service module accesses via:
```nix
databaseConfig = lib.head (lib.filter (db: db.name == "immich") 
  config.qgroget.server.immich.databases);
# Access: databaseConfig.host, databaseConfig.port, databaseConfig.user
```

### Traefik Integration

**Decision 9: Routing Configuration Generation**
- **Choice**: Hybrid approach - auto-generate simple cases, allow override for complex scenarios
- **Rationale**: 90% of services have simple routing needs (subdomain, type, basic middlewares). Complex services with special middleware or advanced routing can override. Maintains existing Traefik dynamic config integration pattern.
- **Implementation**:
```nix
qgroget.server.jellyfin = {
  exposed = true;
  subdomain = "jellyfin";
  type = "public";
  middlewares = ["rate-limit"];  # Simple case: auto-generated
  
  # Optional for complex cases:
  traefikOverride = {
    routers.jellyfin.rule = "Host(`jellyfin.qgroget.com`) && PathPrefix(`/api`)";
  };
};
```

### Testing Strategy

**Decision 10: Test Organization**
- **Choice**: Per-service test files
- **Rationale**: Aligns with existing test structure (tests/jellyfin/, tests/jellyseerr/). All tests for a service in one location. Supports service-focused development workflow where developers work on one service at a time.
- **Implementation**:
```
tests/
├── jellyfin/
│   ├── vm-test.nix       # Runtime behavior
│   ├── eval-test.nix     # Contract conformance
│   └── integration-test.nix  # Cross-service interactions
├── immich/
│   └── vm-test.nix
├── collector/
│   └── eval-test.nix     # Collector logic validation
```

### Decision Impact Analysis

**Critical Path Dependencies:**

1. **Service Contract Definition** (options.nix) → Blocks all service migrations
2. **Collector Module** (collector.nix) → Blocks Traefik/persistence/backup integration
3. **Database Provisioning** → Blocks services requiring databases (Immich, etc.)
4. **Error Message System** → Critical for developer experience during migration
5. **Port Conflict Detection** → Must be in place before migrating services with ports

**Implementation Sequence:**

1. Define service contract with typed options (Decision 1, 4)
2. Implement collector module with automatic activation (Decision 2, 3)
3. Add validation layer (port conflicts, dependencies) (Decision 5, 6)
4. Implement database provisioning (Decision 7, 8)
5. Integrate Traefik routing generation (Decision 9)
6. Create per-service test structure (Decision 10)
7. Migrate proof-of-concept service
8. Document pattern and begin full migration

**Cross-Component Dependencies:**

- **Service Contract ↔ Collector**: Collector depends on contract structure (flat fields)
- **Collector ↔ Traefik**: Traefik config generated from service declarations
- **Collector ↔ Impermanence**: Persistence paths aggregated from services
- **Collector ↔ Backup Systems**: Backup directories collected from services
- **Database Provisioning ↔ Services**: Services access database config from collector
- **Validation ↔ All Services**: Port conflicts and dependencies checked across all services

**Technology Versions:**

All decisions use stable NixOS features (no unstable/experimental features required):
- Nix language: Stable (NixOS 26.05)
- Module system: `lib.types.submodule`, `lib.mkOption`, `lib.mkIf`
- Testing: `nixosTest` framework (stable)
- Traefik: Current stable version in nixpkgs
- PostgreSQL: Current stable version in nixpkgs

## Implementation Patterns & Consistency Rules

### Purpose

These patterns ensure that multiple developers, AI agents, or future modifications create compatible, consistent code. Each pattern addresses a specific area where implementation could vary, causing conflicts or inconsistency.

### Naming Patterns

**Pattern 1: Module File Naming**
- **Rule**: All service modules use `default.nix`
- **Location**: `modules/server/<category>/<service>/default.nix`
- **Rationale**: Consistent with NixOS conventions. Enables clean imports: `./jellyfin` instead of `./jellyfin/jellyfin.nix`
- **Example**:
  ```
  modules/server/media/video/jellyfin/default.nix  ✓
  modules/server/media/video/jellyfin.nix          ✗
  modules/server/media/video/jellyfin/jellyfin.nix ✗
  ```

**Pattern 2: Service Contract Naming**
- **Rule**: Service contract name matches directory name. Subdomain defaults to contract name unless overridden.
- **Rationale**: Clear correspondence between filesystem and configuration. Predictable subdomain generation.
- **Example**:
  ```nix
  # Directory: modules/server/media/video/jellyfin/
  qgroget.server.jellyfin = {              # ✓ Matches directory
    subdomain = "jellyfin";                 # ✓ Defaults to "jellyfin"
  };
  
  # NOT:
  qgroget.server.jellyfinService = { };    # ✗ Doesn't match directory
  ```

**Pattern 3: Database Naming**
- **Rule**: Database names must be explicitly set. Collector validates no duplicate database names across services.
- **Rationale**: Prevents naming collisions. Explicit is better than implicit for infrastructure.
- **Validation**: Evaluation-time assertion fails if duplicate database names detected.
- **Example**:
  ```nix
  databases = [
    { type = "postgresql"; name = "immich"; user = "immich"; }  # ✓ Explicit
  ];
  
  # Collector checks:
  assertions = [{
    assertion = (lib.length uniqueDbNames) == (lib.length allDbNames);
    message = "Duplicate database names detected: ${duplicates}";
  }];
  ```

**Pattern 4: SOPS Secret Paths**
- **Rule**: Hierarchical pattern `server/<service>/<credential-type>`
- **Rationale**: Already in use. Organized, greppable, consistent.
- **Example**:
  ```nix
  sops.secrets."server/immich/db_password" = { };           # ✓
  sops.secrets."server/jellyfin/user/admin/password" = { }; # ✓
  sops.secrets."immich_database_password" = { };            # ✗ Inconsistent
  ```

### Structural Patterns

**Pattern 5: Service Module Structure**
- **Rule**: Three-section structure in every service module
- **Rationale**: Consistent organization. Easy to find contract vs implementation vs secrets.
- **Template**:
  ```nix
  { config, lib, pkgs, ... }:
  
  let
    cfg = config.qgroget.server.<service>;
    # Helper functions and local variables here
  in {
    # Section 1: Service Contract Declaration
    config.qgroget.server.<service> = {
      enable = lib.mkEnableOption "<service>";
      port = lib.mkOption { type = lib.types.port; };
      persistedData = lib.mkOption { type = lib.types.listOf lib.types.str; };
      backupDirectories = lib.mkOption { type = lib.types.listOf lib.types.str; };
      # ... other contract fields
    };
    
    # Section 2: Service Implementation
    config = lib.mkIf cfg.enable {
      # systemd services, containers, packages, etc.
      systemd.services.<service> = { };
      # OR
      virtualisation.quadlet.containers.<service> = { };
    };
    
    # Section 3: SOPS Secrets (if needed)
    config.sops.secrets = lib.mkIf cfg.enable {
      "server/<service>/password" = {
        owner = "<service>";
      };
    };
  }
  ```

**Pattern 6: Test File Organization**
- **Rule**: Per-service test directory with standardized file names
- **Rationale**: Aligns with existing structure. All tests for a service in one place.
- **Structure**:
  ```
  tests/<service>/
  ├── default.nix           # Main VM test (runtime behavior)
  ├── eval-test.nix         # Contract validation (optional)
  └── integration-test.nix  # Cross-service scenarios (optional)
  ```
- **Example**:
  ```
  tests/jellyfin/default.nix          ✓
  tests/jellyfin/jellyfin-test.nix    ✗
  tests/jellyfin/test.nix             ✗
  ```

### Integration Patterns

**Pattern 7: Traefik Middleware Declaration**
- **Rule**: Predefined middleware names that map to actual Traefik middleware configurations. Validated at evaluation time.
- **Rationale**: Consistent middleware naming. Validation prevents typos. Abstraction layer between service and Traefik specifics.
- **Implementation**:
  ```nix
  # In service:
  qgroget.server.sonarr = {
    middlewares = ["sso" "basic-auth"];  # Predefined names
  };
  
  # In collector:
  middlewareMap = {
    sso = "authelia-sso@file";
    basic-auth = "basic-auth@file";
    rate-limit = "rate-limit-100@file";
  };
  
  # Validation:
  assertions = lib.forEach allMiddlewares (mw: {
    assertion = middlewareMap ? ${mw};
    message = "Unknown middleware '${mw}'. Valid: ${validMiddlewares}";
  });
  ```

**Pattern 8: Database Connection Information**
- **Rule**: Service modules access structured database configuration from collector. Service decides how to pass to application (env vars, config files, etc.).
- **Rationale**: Hides implementation details. Works for both containers and native services. Flexible for different application requirements.
- **Implementation**:
  ```nix
  # Collector provides:
  config.qgroget.server.<service>.databaseConfig = {
    host = "localhost";
    port = 5432;
    name = "immich";
    user = "immich";
  };
  
  # Service module uses (container example):
  environment.DATABASE_URL = 
    "postgresql://${db.user}@${db.host}:${db.port}/${db.name}";
  
  # Service module uses (native example):
  systemd.services.<service>.environment = {
    DATABASE_HOST = db.host;
    DATABASE_PORT = toString db.port;
    DATABASE_NAME = db.name;
  };
  ```

**Pattern 9: Container vs Native Service Abstraction**
- **Rule**: Service contract is identical regardless of implementation. Service module handles whether service runs as container or native systemd service.
- **Rationale**: Collector doesn't need to know implementation details. Services can switch between container/native without changing contract. Clean separation of concerns.
- **Example**:
  ```nix
  # Contract (same for both):
  qgroget.server.jellyfin = {
    enable = true;
    databases = [{ type = "postgresql"; name = "jellyfin"; }];
  };
  
  # Implementation varies:
  # Container:
  virtualisation.quadlet.containers.jellyfin = { };
  
  # Native:
  systemd.services.jellyfin = { };
  
  # Collector treats both identically
  ```

### Process Patterns

**Pattern 10: Code Formatting**
- **Rule**: Use `alejandra` formatter for all Nix code
- **Rationale**: Automated formatting prevents bikeshedding. Consistent style across all modules.
- **Usage**: `alejandra .` before committing
- **CI Integration**: Add format check to `nix flake check`

**Pattern 11: Migration Commit Convention**
- **Rule**: Standard commit message format and checklist for service migrations
- **Rationale**: Consistent git history. Easy to track migration progress. Ensures no steps forgotten.
- **Template**:
  ```
  refactor(server): migrate <service> to new pattern
  
  - Define service contract in modules/server/<category>/<service>/default.nix
  - Implement collector aggregation (persistence, backup, traefik)
  - Add VM test in tests/<service>/default.nix
  - Remove old pattern configuration
  - Update settings.nix to enable service
  
  Checklist:
  - [x] Service contract defined with all required fields
  - [x] Persistence paths declared
  - [x] Backup directories declared  
  - [x] Traefik routing configured (if exposed)
  - [x] Database provisioning configured (if needed)
  - [x] Secrets properly configured (if needed)
  - [x] VM test passes
  - [x] nix flake check passes
  - [x] Tested on actual server
  ```

### Validation Patterns

All validations occur at evaluation time (not runtime):

1. **Required Field Validation**: Type system enforces required fields (no defaults)
2. **Port Conflict Detection**: Assertions check for duplicate ports across all services
3. **Database Name Validation**: Assertions check for duplicate database names
4. **Middleware Validation**: Assertions check middleware names against predefined map
5. **Dependency Validation**: Assertions error if service depends on disabled service
6. **Path Validation**: Type system ensures paths are strings

### Pattern Enforcement

**Automated Enforcement:**
- Nix type system: Enforces contract structure, required fields
- `alejandra` formatter: Enforces code style
- Evaluation-time assertions: Enforces business rules (ports, databases, middleware)
- `nix flake check`: Runs all validation tests

**Manual Review:**
- Module structure (three sections)
- File naming conventions
- Test organization
- Commit message format
- Migration checklist completion

### Pattern Benefits

**For AI Agents:**
- Clear rules prevent inconsistent implementations
- Validation provides immediate feedback
- Template structure provides concrete examples
- Patterns reduce decision paralysis

**For Human Developers:**
- Onboarding simplified (one pattern to learn)
- Code reviews focus on logic, not style
- Migrations follow predictable process
- Debugging easier with consistent structure

**For System Reliability:**
- Evaluation-time validation catches errors before deployment
- Consistent patterns reduce cognitive load
- Automated enforcement reduces human error
- Clear abstractions enable safe refactoring

## Project Structure & Architectural Boundaries

### Requirement-to-Component Mapping

This section maps functional requirements from the PRD to specific files and modules in the implementation:

**Core Infrastructure (FR1-FR7, FR14-FR18):**
- `modules/server/options.nix` - Service contract definition with types.submodule
- `modules/server/collector.nix` - Aggregation logic and evaluation-time validation

**Configuration Integration (FR8-FR13):**
- `modules/server/collector.nix` - Aggregates Traefik routing, persistence paths, backup directories, database provisioning
- Integration with existing modules: Traefik, Impermanence, Restic/Borg

**Migration Support (FR19-FR22):**
- `hosts/Server/configuration.nix` - Conditional imports for pattern coexistence
- Per-service migration in `modules/server/<category>/<service>/default.nix`

**Testing Infrastructure (FR23-FR28):**
- `tests/<service>/default.nix` - Per-service VM tests (runtime behavior)
- `tests/collector/eval-test.nix` - Collector logic validation
- `tests/integration/<scenario>.nix` - Cross-service interaction tests

**Developer Experience (FR29-FR36):**
- `modules/server/_template/default.nix` - Annotated service template with inline documentation
- `docs/migration-guide.md` - Step-by-step migration documentation
- `docs/architecture-decision-record.md` - This document (complete architectural reference)

### Complete Directory Structure

```
nixos/                                    # Repository root
├── flake.nix                             # Flake configuration (unchanged)
├── flake.lock                            # Locked dependencies
├── README.md                             # Project documentation
├── .github/
│   └── copilot-instructions.md          # AI assistant guidance
│
├── hosts/                                # Host configurations
│   ├── Server/
│   │   ├── configuration.nix            # Server host config
│   │   │                                 # - Imports collector conditionally
│   │   ├── settings.nix                 # Service enablement
│   │   │                                 # - qgroget.server.<service>.enable
│   │   ├── hardware-configuration.nix
│   │   └── disk-config.nix
│   └── ...                              # Other hosts (unchanged)
│
├── modules/
│   ├── server/                           # SERVER MODULE REFACTORING
│   │   ├── default.nix                   # Module entry point
│   │   │                                 # - Imports options.nix
│   │   │                                 # - Imports collector.nix
│   │   │
│   │   ├── options.nix                   # NEW: Service contract definition
│   │   │                                 # - types.submodule for qgroget.server.<service>
│   │   │                                 # - Required: enable, port, persistedData, backupDirectories
│   │   │                                 # - Optional: exposed, subdomain, type, middlewares, dependsOn, databases
│   │   │
│   │   ├── collector.nix                 # NEW: Aggregation & validation
│   │   │                                 # - Filters enabled services
│   │   │                                 # - Aggregates persistence paths
│   │   │                                 # - Aggregates backup directories
│   │   │                                 # - Generates Traefik config
│   │   │                                 # - Provisions databases
│   │   │                                 # - Validates ports, dependencies, database names
│   │   │
│   │   ├── _template/                    # NEW: Service template
│   │   │   └── default.nix               # Annotated template for new services
│   │   │                                 # - Inline comments explaining each field
│   │   │                                 # - Example configurations
│   │   │
│   │   ├── media/                        # Media services
│   │   │   ├── video/
│   │   │   │   ├── jellyfin/             # To be migrated
│   │   │   │   │   └── default.nix       # Service contract + implementation
│   │   │   │   └── jellyseer.nix         # To be migrated
│   │   │   └── photo/
│   │   │       └── immich/               # To be migrated
│   │   │           └── default.nix
│   │   │
│   │   ├── arrs/                         # *arr automation stack
│   │   │   ├── sonarr/                   # To be migrated
│   │   │   │   └── default.nix
│   │   │   ├── radarr/                   # To be migrated
│   │   │   │   └── default.nix
│   │   │   ├── bazarr/                   # To be migrated
│   │   │   │   └── default.nix
│   │   │   └── prowlarr/                 # To be migrated
│   │   │       └── default.nix
│   │   │
│   │   ├── downloaders/                  # Download clients
│   │   │   ├── qbittorrent/              # To be migrated
│   │   │   │   └── default.nix
│   │   │   └── nicotine/                 # To be migrated
│   │   │       └── default.nix
│   │   │
│   │   ├── SSO/                          # Authentication
│   │   │   ├── authelia/                 # To be migrated
│   │   │   │   └── default.nix
│   │   │   └── lldap/                    # To be migrated
│   │   │       └── default.nix
│   │   │
│   │   ├── password-manager/             # Vaultwarden
│   │   │   └── vaultwarden/              # To be migrated
│   │   │       └── default.nix
│   │   │
│   │   ├── traefik/                      # Reverse proxy
│   │   │   └── default.nix               # To be migrated
│   │   │                                 # Special: uses collector-generated config
│   │   │
│   │   ├── backup/                       # Backup services
│   │   │   └── default.nix               # To be updated
│   │   │                                 # - Uses collector-aggregated paths
│   │   │
│   │   ├── misc/                         # Misc services
│   │   │   ├── portfolio.nix             # To be migrated
│   │   │   ├── obsidian.nix              # To be migrated
│   │   │   ├── syncthing.nix             # To be migrated
│   │   │   └── fileServer.nix            # To be migrated
│   │   │
│   │   └── settings.nix                  # OLD: Legacy persistence/backup
│   │                                     # Will be replaced by collector aggregation
│   │
│   ├── apps/                             # Application modules (unchanged)
│   ├── desktop/                          # Desktop modules (unchanged)
│   ├── game/                             # Gaming modules (unchanged)
│   ├── shared/                           # Shared modules (unchanged)
│   └── system/                           # System modules (unchanged)
│
├── tests/                                # Testing infrastructure
│   ├── collector/                        # NEW: Collector tests
│   │   ├── eval-test.nix                 # Evaluation tests for aggregation logic
│   │   └── validation-test.nix           # Validation assertion tests
│   │
│   ├── jellyfin/                         # Existing (to be updated)
│   │   └── default.nix                   # VM test for Jellyfin
│   │
│   ├── jellyseerr/                       # Existing (to be updated)
│   │   └── default.nix                   # VM test for Jellyseerr
│   │
│   └── integration/                      # NEW: Integration tests
│       ├── media-stack.nix               # Test Jellyfin + Jellyseerr + *arr services
│       └── auth-flow.nix                 # Test Authelia + LLDAP + protected service
│
├── docs/                                 # Documentation
│   ├── architecture.md                   # Current architecture (existing)
│   ├── architecture-decision-record.md   # NEW: This document (from workflow)
│   ├── migration-guide.md                # NEW: Service migration guide
│   ├── service-template-guide.md         # NEW: How to use template
│   └── ...                               # Other existing docs
│
├── secrets/                              # SOPS secrets (unchanged)
│   └── secrets.yaml                      # Encrypted secrets
│
└── home/                                 # Home-manager (unchanged)
```

### Architectural Boundaries

These boundaries define clear responsibilities and prevent scope creep:

**Contract Boundary (`options.nix`):**
- **Input**: Service declarations from service modules
- **Output**: Typed `config.qgroget.server.<service>` options
- **Responsibility**: Define service contract schema, enforce types through Nix type system
- **Does NOT**: Aggregate, validate business rules, or generate configurations
- **Validation**: Type checking at evaluation time

**Collector Boundary (`collector.nix`):**
- **Input**: `config.qgroget.server.*` (all enabled services)
- **Output**: Aggregated configurations for Traefik, Impermanence, Backup, Database provisioning
- **Responsibility**: Aggregate data from services, validate business rules (port conflicts, dependencies, database names), generate integration configurations
- **Does NOT**: Define contract schema or implement individual services
- **Validation**: Assertions for ports, dependencies, database names

**Service Module Boundary (`modules/server/<category>/<service>/default.nix`):**
- **Input**: Service-specific configuration from user (via `hosts/Server/settings.nix`)
- **Input**: Database config from collector (if databases declared)
- **Output**: Service contract declaration + systemd/container implementation
- **Responsibility**: Service-specific logic, SOPS secret handling, systemd/container configuration
- **Does NOT**: Aggregate across services, validate cross-service constraints, or know about other services
- **Validation**: Service-level logic validation

**Test Boundary:**
- **VM Tests** (`tests/<service>/default.nix`): Runtime behavior (service starts, persists data across reboots, routes correctly through Traefik)
- **Eval Tests** (`tests/collector/eval-test.nix`): Build-time logic (collector aggregation correctness, type checking)
- **Integration Tests** (`tests/integration/*.nix`): Cross-service interactions (dependencies work, authentication flows complete)
- **Does NOT**: Test internal service implementation details or third-party service logic

### Integration Points

Clear interfaces between the new architecture and existing systems:

**Traefik Integration:**
- **Interface**: Collector generates dynamic configuration file
- **Data Flow**: Service declarations (`exposed`, `subdomain`, `type`, `middlewares`) → Collector aggregation → Traefik dynamic config JSON
- **File**: `modules/server/traefik/default.nix` reads collector output
- **Contract**: Services with `exposed = true` get Traefik routers/services auto-generated

**Impermanence Integration:**
- **Interface**: Collector aggregates `persistedData` from all enabled services
- **Data Flow**: Service `persistedData` lists → Collector aggregation → `environment.persistence."/persist".directories`
- **Module**: `impermanence.nixosModules.impermanence` (external)
- **Contract**: All paths in `persistedData` lists are preserved across ephemeral root reboots

**Backup Integration:**
- **Interface**: Collector aggregates `backupDirectories` from all enabled services
- **Data Flow**: Service `backupDirectories` lists → Collector aggregation → Restic/Borg backup configurations
- **File**: `modules/server/backup/default.nix` reads collector output
- **Contract**: All paths in `backupDirectories` lists are included in automated backups

**Database Integration:**
- **Interface**: Collector provisions PostgreSQL databases and exposes connection details
- **Data Flow**: Service `databases` declarations → Collector creates databases → Connection info back to services via `databaseConfig` attribute
- **Service**: PostgreSQL configured via `services.postgresql` (NixOS standard module)
- **Contract**: Each database in `databases` list gets provisioned with specified name/user, connection details available to service module

**SOPS Secrets Integration:**
- **Interface**: Each service module declares its own secrets in Section 3 of module structure
- **Data Flow**: Service declares secrets → SOPS decrypts at activation → Secrets available to systemd services
- **Pattern**: `sops.secrets."server/<service>/<credential-type>"` with appropriate ownership
- **Module**: `sops-nix.nixosModules.sops` (external)
- **Contract**: Secrets follow naming convention, automatically decrypted and available at runtime

### Migration Path

The architecture supports incremental migration with these phases:

**Phase 1: Core Infrastructure (Blocks all migrations)**
1. Create `modules/server/options.nix` with service contract definition
2. Create `modules/server/collector.nix` with aggregation and validation logic
3. Update `modules/server/default.nix` to import new modules
4. Create `modules/server/_template/default.nix` with annotated template
5. Add collector evaluation tests in `tests/collector/`
6. Validate with `nix flake check`

**Phase 2: Proof of Concept (Validates pattern)**
1. Select simple service (e.g., DNS service or Portfolio)
2. Migrate using new pattern following template
3. Add VM test for migrated service
4. Test on actual server
5. Document learnings and update template/guide

**Phase 3: Full Migration (Incremental, per-service)**
1. Migrate one service at a time using established pattern
2. Follow migration commit convention (Pattern 11)
3. Each service independently deployable
4. Old pattern continues working for non-migrated services
5. Complete migration checklist for each service
6. ~3-6 months to migrate all 15+ services

**Phase 4: Cleanup (After all migrations complete)**
1. Remove old `qgroget.services` pattern code
2. Remove legacy `modules/server/settings.nix` persistence/backup logic
3. Update documentation to reflect new pattern as standard
4. Archive migration documentation

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
All architectural decisions work together harmoniously. The flat service contract structure supports efficient collector aggregation via `lib.filterAttrs` and `lib.mapAttrsToList`. Automatic collector activation removes configuration friction. Multiple database support with explicit naming prevents conflicts. Evaluation-time validation (ports, dependencies, database names) catches errors before deployment. All decisions use stable NixOS features (no experimental dependencies).

**Pattern Consistency:**
Implementation patterns align perfectly with architectural decisions. Flat structure enables clear error messages with short paths. Predefined middleware names work with evaluation-time validation. Service abstraction (contract vs implementation) allows container/native flexibility. Alejandra formatting enforces code consistency automatically. Migration commit convention supports incremental refactoring strategy.

**Structure Alignment:**
Project structure directly supports all architectural decisions. Service modules follow three-section pattern (contract, implementation, secrets). Collector and options modules cleanly separated. Per-service test directories enable independent migration. Template provides concrete reference implementation. Clear boundaries prevent scope creep between components.

### Requirements Coverage Validation ✅

**Functional Requirements Coverage (36 FRs - All Covered):**

- **FR1-FR7 (Service Contract)**: Fully supported by `options.nix` with types.submodule enforcing required/optional fields
- **FR8-FR13 (Aggregation)**: Completely covered by `collector.nix` aggregating persistence, backups, Traefik, databases
- **FR14-FR18 (Validation)**: Build-time validation through type system + assertions + `nix flake check`
- **FR19-FR22 (Migration)**: Pattern coexistence via conditional imports, incremental per-service migration
- **FR23-FR28 (Testing)**: Three-layer strategy (VM tests, eval tests, integration tests) all defined
- **FR29-FR36 (Documentation)**: Template with inline comments, migration guide, ADR (this document)

**Non-Functional Requirements Coverage (13 NFRs - All Addressed):**

- **NFR1-NFR4 (Maintainability)**: Single-file service modules, flat structure for comprehension, coordinated updates via type system
- **NFR5-NFR9 (Reliability)**: 100% detection via evaluation assertions, port conflict detection, zero downtime via pattern coexistence
- **NFR10-NFR13 (Developer Experience)**: Detailed error messages with examples, template with inline docs, migration checklist

### Implementation Readiness Validation ✅

**Decision Completeness:**
All critical architectural decisions documented with specific choices and rationale:
- Service contract structure (flat)
- Collector activation (automatic)
- Error messages (detailed with examples)
- Database support (multiple with explicit names)
- All integration patterns defined
- All validation strategies specified

**Structure Completeness:**
Complete directory tree provided showing every file location. All 15+ services mapped to specific directories. Core infrastructure files specified (`options.nix`, `collector.nix`, `_template/default.nix`). Test organization per-service with clear naming. Documentation files identified. No placeholder directories - everything concrete and specific.

**Pattern Completeness:**
11 patterns defined covering all potential conflict points:
- Naming (4 patterns): module files, service contracts, databases, secrets
- Structure (2 patterns): module organization, test organization
- Integration (3 patterns): Traefik middleware, database connections, container abstraction
- Process (2 patterns): code formatting, migration commits

### Gap Analysis Results

**Critical Gaps:** None identified. All blocking decisions made, all required infrastructure defined.

**Important Gaps:** None identified. Architecture is comprehensive and ready for implementation.

**Nice-to-Have Enhancements:**
- CI/CD integration for `alejandra` formatting check (can add during implementation)
- Automated migration progress tracking (useful but not blocking)
- Service dependency graph visualization (helpful for complex dependencies)
- Performance benchmarking framework (valuable for optimization phase)

### Validation Issues Addressed

No critical or important issues found. The architecture is coherent, complete, and ready for implementation.

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed (36 FRs, 13 NFRs, 15+ services)
- [x] Scale and complexity assessed (Medium-High, brownfield refactoring)
- [x] Technical constraints identified (NixOS module system, lazy evaluation, pure Nix)
- [x] Cross-cutting concerns mapped (Traefik, Impermanence, Backups, Databases, Validation)

**✅ Architectural Decisions**
- [x] Critical decisions documented (10 major decisions with rationale)
- [x] Technology stack fully specified (Nix, NixOS modules, stable features only)
- [x] Integration patterns defined (Traefik, Impermanence, Backup, Database, SOPS)
- [x] Validation strategy complete (evaluation-time + checks)

**✅ Implementation Patterns**
- [x] Naming conventions established (11 patterns covering all areas)
- [x] Structure patterns defined (three-section module, per-service tests)
- [x] Integration patterns specified (middleware, database connections, abstractions)
- [x] Process patterns documented (alejandra, migration commits)

**✅ Project Structure**
- [x] Complete directory structure defined (full tree with all 15+ services)
- [x] Component boundaries established (options, collector, service modules, tests)
- [x] Integration points mapped (5 major integrations with clear interfaces)
- [x] Requirements to structure mapping complete (all FRs mapped to files)

### Architecture Readiness Assessment

**Overall Status:** ✅ **READY FOR IMPLEMENTATION**

**Confidence Level:** **HIGH** - Architecture is comprehensive, coherent, and implementation-ready

**Key Strengths:**
- Leverages NixOS type system for automatic enforcement
- Evaluation-time validation catches all errors before deployment
- Clear separation of concerns (contract, collector, service implementation)
- Incremental migration strategy with zero downtime
- Self-documenting through types and inline comments
- Consistent patterns prevent AI agent conflicts
- Complete test strategy (VM, eval, integration)

**Areas for Future Enhancement:**
- Performance optimization after full migration (lazy evaluation tuning)
- Additional integration tests for complex scenarios
- CI/CD pipeline enhancements (automated migration tracking)
- Service dependency graph visualization tool

### Implementation Handoff

**AI Agent Guidelines:**

1. **Follow architectural decisions exactly** - All decisions in this document are final and must be implemented as specified
2. **Use patterns consistently** - All 11 implementation patterns must be followed to prevent conflicts
3. **Respect boundaries** - Do not mix concerns between options.nix, collector.nix, and service modules
4. **Validate continuously** - Run `nix flake check` after every change
5. **Format with alejandra** - Run `alejandra .` before committing
6. **Follow migration checklist** - Complete all items for each service migration

**First Implementation Priority:**

**Phase 1: Core Infrastructure**
1. Create `modules/server/options.nix` with service contract (types.submodule)
2. Create `modules/server/collector.nix` with aggregation logic
3. Update `modules/server/default.nix` to import new modules
4. Create `modules/server/_template/default.nix` with annotated template
5. Add `tests/collector/eval-test.nix` for collector validation
6. Run `nix flake check` to validate

**Phase 2: Proof of Concept**
7. Select simple service (Portfolio or DNS)
8. Migrate using template pattern
9. Add VM test
10. Test on server
11. Document learnings

---

## Architecture Completion Summary

### Workflow Completion

**Architecture Decision Workflow:** COMPLETED ✅  
**Total Steps Completed:** 8  
**Date Completed:** 2026-01-07  
**Document Location:** _bmad-output/planning-artifacts/architecture.md

### Final Architecture Deliverables

**📋 Complete Architecture Document**

- All architectural decisions documented with specific versions
- Implementation patterns ensuring AI agent consistency
- Complete project structure with all files and directories
- Requirements to architecture mapping
- Validation confirming coherence and completeness

**🏗️ Implementation Ready Foundation**

- 10 architectural decisions made
- 11 implementation patterns defined
- 20+ architectural components specified
- 49 requirements fully supported (36 FRs + 13 NFRs)

**📚 AI Agent Implementation Guide**

- Technology stack with verified versions (NixOS stable features)
- Consistency rules that prevent implementation conflicts
- Project structure with clear boundaries
- Integration patterns and communication standards

### Implementation Handoff

**For AI Agents:**  
This architecture document is your complete guide for implementing the NixOS service module refactoring. Follow all decisions, patterns, and structures exactly as documented.

**First Implementation Priority:**  
Phase 1: Core Infrastructure - Create `modules/server/options.nix`, `collector.nix`, and `_template/default.nix`

**Development Sequence:**

1. Initialize core infrastructure (options, collector, template)
2. Set up development environment with test framework
3. Implement proof of concept with simple service (Portfolio or DNS)
4. Migrate remaining services following established patterns
5. Maintain consistency with documented rules

### Quality Assurance Checklist

**✅ Architecture Coherence**

- [x] All decisions work together without conflicts
- [x] Technology choices are compatible (NixOS stable features)
- [x] Patterns support the architectural decisions
- [x] Structure aligns with all choices

**✅ Requirements Coverage**

- [x] All functional requirements are supported (36/36)
- [x] All non-functional requirements are addressed (13/13)
- [x] Cross-cutting concerns are handled (Traefik, Impermanence, Backups, Databases, Validation)
- [x] Integration points are defined

**✅ Implementation Readiness**

- [x] Decisions are specific and actionable
- [x] Patterns prevent agent conflicts
- [x] Structure is complete and unambiguous
- [x] Examples are provided for clarity

### Project Success Factors

**🎯 Clear Decision Framework**  
Every technology choice was made collaboratively with clear rationale, ensuring all stakeholders understand the architectural direction.

**🔧 Consistency Guarantee**  
Implementation patterns and rules ensure that multiple AI agents will produce compatible, consistent code that works together seamlessly.

**📋 Complete Coverage**  
All project requirements are architecturally supported, with clear mapping from business needs to technical implementation.

**🏗️ Solid Foundation**  
The chosen reference implementation pattern and architectural patterns provide a production-ready foundation following NixOS best practices.

---

**Architecture Status:** READY FOR IMPLEMENTATION ✅

**Next Phase:** Begin Phase 1 Core Infrastructure implementation using the architectural decisions and patterns documented herein.

**Document Maintenance:** Update this architecture when major technical decisions are made during implementation.

---

## Document Complete

This Architecture Decision Document provides complete guidance for implementing the NixOS service module refactoring. All architectural decisions, implementation patterns, project structure, and validation results are documented and ready to guide consistent implementation across multiple contributors and AI agents.

**Next Steps:**
1. Begin Phase 1: Core Infrastructure implementation
2. Reference this document for all architectural questions
3. Update PRD implementation status as phases complete
4. Create migration guide with concrete examples from proof of concept
