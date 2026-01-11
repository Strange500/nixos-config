---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
inputDocuments:
  - _bmad-output/planning-artifacts/brainstorming-session-2026-01-06.md
  - docs/index.md
  - docs/project-overview.md
  - docs/architecture.md
workflowType: 'prd'
lastStep: 10
---

# Product Requirements Document - nixos

**Author:** Strange
**Date:** 2026-01-06

## Executive Summary

This PRD defines a comprehensive refactoring of the NixOS server service module architecture. The current system has grown organically, resulting in inconsistent service definitions, missing persistence/backup declarations, and no systematic way to validate configurations before deployment.

The refactoring introduces a **service-centric architecture** where each service declares itself under `qgroget.server.<serviceName>` with a standardized contract, while a **collector module** aggregates these declarations into Traefik routes, persistence paths, backup configurations, and database provisioning.

### What Makes This Special

1. **Enforced Correctness** - The new service contract makes it impossible to add a service without explicitly declaring persistence and backup paths. This shifts from "hope developers remember" to "Nix evaluation fails if they forget" - catching configuration errors at build time, not in production.

2. **Self-Documenting Infrastructure** - Service enablement is controlled from a single location, while all configuration details remain encapsulated in uniform service modules. Understanding the server no longer requires spelunking through the entire repository.

3. **Testable Infrastructure** - The refactoring enables multiple validation layers: NixOS VM tests for runtime verification, Nix evaluation tests for collector logic, and schema validation to ensure every service conforms to the contract.

## Project Classification

| Attribute | Value |
|-----------|-------|
| **Technical Type** | Infrastructure-as-Code / NixOS Module System |
| **Domain** | General (internal infrastructure tooling) |
| **Complexity** | Medium-High |
| **Project Context** | Brownfield - refactoring existing NixOS configuration |
| **Migration Strategy** | Incremental - one service at a time with pattern coexistence |

## Success Criteria

### User Success (Infrastructure Maintainer)

**The "Worth It" Moment:**
Adding a new service becomes straightforward and quick. You open a clear template, fill in service-specific configuration, and the system handles all the common patterns automatically. When you run `nix flake check`, any mistakes are caught immediately with clear error messages, not discovered hours later during deployment.

**Measurable Outcomes:**
- **Time Efficiency**: Common configuration overhead reduced by ~67% - focus shifts entirely to service-specific needs
- **Template Clarity**: Adding a new service requires editing only one service module file with < 50 lines for standard services
- **Error Prevention**: Build-time validation catches missing persistence declarations, backup paths, and permission issues before deployment
- **Confidence**: Can deploy knowing that if `nix flake check` passes, the service is properly configured

### Business Success (Operational Metrics)

**Reliability Improvements:**
- **Zero configuration-related incidents**: No missing folders, no permission errors, no forgotten backups
- **Complete backup coverage**: Every service that needs backup is backed up - enforced by build system
- **Deployment safety**: Configuration errors caught at build time, not in production

**Development Velocity:**
- **Faster service additions**: Service-specific configuration becomes the bottleneck, not hunting for where to declare persistence/backups
- **Migration timeline**: All existing services migrated within 3-6 months
- **Code maintainability**: Clean, uniform codebase that new contributors can understand quickly

### Technical Success

**Core Requirements:**
1. **Service Contract Enforcement**: Build fails if any service is missing required declarations (persistence, backups)
2. **Collector Module**: Successfully aggregates all enabled services into Traefik routes, persistence, backups, and database provisioning
3. **Validation Tests**: NixOS VM tests verify services start correctly; schema tests validate service declarations
4. **Pattern Coexistence**: Old and new patterns work simultaneously during migration period
5. **Clean Abstraction**: Services don't know if they're containers or native - implementation detail hidden

**Quality Metrics:**
- All services follow identical contract
- No scattered configuration across multiple files
- Self-documenting: reading one service module tells you everything about that service
- Evaluation-time dependency validation (warns if service depends on disabled service)

### Measurable Outcomes

**At 1 Month (MVP Complete):**
- Service contract defined and enforced
- Collector module working
- 2-3 services migrated as proof of concept
- Build-time validation catching errors

**At 3 Months (Migration In Progress):**
- 50%+ of services migrated
- Zero configuration incidents for migrated services
- Time savings measurable on new service additions

**At 6 Months (Migration Complete):**
- All services migrated to new pattern
- Old pattern code removed
- Clean, maintainable codebase
- Documentation updated with new patterns

## Product Scope

### MVP - Minimum Viable Product

**Must Have for Usefulness:**
1. **Base Service Contract** (`options.nix`):
   - Required fields: `enable`, `port`, `persistedData`, `backupDirectories`
   - Optional fields: `exposed`, `subdomain`, `type`, `middlewares`, `dependsOn`, `database`
   
2. **Collector Module** (`collector.nix`):
   - Aggregates persistence directories from enabled services
   - Aggregates backup paths from enabled services
   - Generates Traefik dynamic configuration for exposed services
   - Auto-provisions PostgreSQL databases based on service declarations
   - Validates dependencies at evaluation time

3. **Service Migration Template**:
   - Clear example showing how to migrate a service
   - Documentation on the contract

4. **Proof of Concept Migration**:
   - Migrate 1-2 simple services (e.g., DNS service)
   - Validate pattern works end-to-end
   - Coexistence with old pattern proven

5. **Basic Validation**:
   - Build-time error if required fields missing
   - `nix flake check` catches basic configuration errors

### Growth Features (Post-MVP)

**Make It Competitive (vs current manual patterns):**
1. **Comprehensive Tests**:
   - NixOS VM tests for all migrated services
   - Schema validation tests for service contract
   - Integration tests for collector module

2. **Enhanced Validation**:
   - Dependency cycle detection
   - Port conflict detection
   - Path overlap detection (multiple services writing to same directory)

3. **Migration Tooling**:
   - Script to help convert existing services to new pattern
   - Automated checks to identify what needs migrating

4. **Complete Service Migration**:
   - All 15+ services migrated to new pattern
   - Old `qgroget.services` pattern removed
   - Clean module structure

5. **Documentation**:
   - Architecture decision records
   - Service addition guide
   - Migration guide for future services

### Vision (Future)

**Dream Version:**
1. **Auto-Discovery**: Services can be auto-discovered from directory structure
2. **Service Templates**: Pre-built templates for common service types (media server, *arr app, authentication service)
3. **Monitoring Integration**: Service contract automatically creates monitoring/alerting configurations
4. **Backup Verification**: Automated tests that backups are restorable
5. **Multi-Host Support**: Pattern extends to manage services across multiple NixOS hosts
6. **GUI Configuration**: Web UI for enabling/configuring services (generates Nix code)

## User Journeys

### Journey 1: Strange - The "Quick" Service Addition That Wasn't

It's late evening, and Strange discovers Paperless-NGX on Reddit - a document management system that could finally organize years of scattered PDFs. Excited, he decides to add it to his homelab that night.

He creates `modules/server/paperless/default.nix` and configures the container - that part is straightforward, takes 20 minutes. He sets the port, maps the volumes, feels productive. He commits the changes, runs `nixos-rebuild switch`, and the service starts successfully. Victory!

Or so he thinks.

Two days later, he reboots the server for kernel updates. Paperless comes back up, but all his documents are gone. He forgot to add `/var/lib/paperless` to the impermanence persistence configuration. That's in `modules/server/settings.nix`, a completely different file he didn't even open.

He adds the persistence path, redeploys. Documents persist now, but he notices permission errors in the logs - the container can't write to certain directories. He spends an hour debugging systemd tmpfiles rules and container user mappings.

A week later, his automated backup system runs. He reviews the backup logs and realizes Paperless data isn't being backed up. That's declared in yet another location - `modules/server/backup/default.nix`. He adds it, finally feels complete.

Three separate files edited, three separate discoveries of missing configuration, across multiple days. The service works now, but the scattered declarations haunt him: "What else did I forget?"

**With the new system:**

Strange discovers Paperless-NGX. He opens `modules/server/paperless/default.nix` and starts from the service template. The contract is right there at the top, showing exactly what he must declare:

```nix
qgroget.server.paperless = {
  enable = true;
  port = 8010;
  persistedData = [ "/var/lib/paperless" ];  # REQUIRED - can't skip
  backupDirectories = [ "/var/lib/paperless/data" ];  # REQUIRED - can't skip
  exposed = true;
  subdomain = "paperless";
  type = "private";
};
```

He fills it in - everything about Paperless is right here. Service config, persistence, backups, routing - all in one place. Before deploying, he runs `nix flake check`.

The check passes. He deploys confidently, knowing that if he'd forgotten persistence or backups, the build would have failed with a clear error message. The service works. It persists across reboots. It's backed up. He moves on to the next thing.

**This journey reveals requirements for:**
- Service contract with enforced required fields
- Build-time validation that catches missing declarations
- Single-file service definition (no scattered configuration)
- Clear template showing exactly what must be declared

### Journey 2: Strange - Migrating Jellyfin Without Breaking Movie Night

It's Saturday afternoon. Strange has been working on the new service architecture for a week, and he's ready to migrate his first real service: Jellyfin. His family uses it every evening for movies. Breaking it isn't an option.

He opens `modules/server/media/video/default.nix` - 200 lines of configuration accumulated over months. There's the main service definition, but persistence is declared in `settings.nix`, backups in `backup/default.nix`, and Traefik routing in `traefik/default.nix`. He needs to gather all of this into one place without disrupting the running service.

He creates `modules/server/media/video/jellyfin.nix` following the new pattern, carefully mapping all the scattered configuration into the new contract:

```nix
qgroget.server.jellyfin = {
  enable = true;
  port = 8096;
  persistedData = [ "/var/lib/jellyfin" ];
  backupDirectories = [ "/var/lib/jellyfin/data" ];
  exposed = true;
  subdomain = "jellyfin";
  type = "public";
  # ... service-specific config
};
```

The critical moment: he keeps the old pattern running but adds `qgroget.server.jellyfin.enable = true;` in `settings.nix`. Both patterns coexist. He runs `nix flake check` - no errors. He does a dry-run build: `nixos-rebuild dry-build`. Everything looks clean.

He deploys. Jellyfin stays up. The new declaration is registered, but the old systemd service is still running. He can see the new config is correct by checking what the collector module generated. Once confirmed, he disables the old pattern, redeploys. Seamless cutover.

Movie night proceeds as usual. His family never knew anything changed. But Strange knows: Jellyfin's configuration is now clean, self-documenting, and impossible to misconfigure.

**This journey reveals requirements for:**
- Pattern coexistence (old and new working simultaneously)
- Clear migration guide/template
- Validation that doesn't break existing services
- Ability to verify new configuration before cutover

### Journey 3: Strange - The 2 AM Production Debug

It's 2 AM. Strange's phone buzzes with a monitoring alert: Immich (photo service) is down. His family uses it daily for sharing photos. He needs to fix this fast.

In the current system, he opens `modules/server/media/photo/default.nix` to understand the service configuration. But to see persistence paths, he needs to check `settings.nix`. For backups, he opens `backup/default.nix`. Traefik routing is in yet another file. The logs show a permission error, but where are the systemd tmpfiles rules declared? He's jumping between files, losing context, struggling to build a mental model while half-asleep.

**With the new system:**

The alert comes in at 2 AM. Strange opens `modules/server/media/photo/immich.nix`. Everything is there: service config, persistence paths, backup directories, routing rules, database configuration. One file, complete picture.

The error message is clear: "Permission denied: /var/lib/immich/upload". He sees the `persistedData` declaration right there, immediately understands the issue - the upload directory isn't in the persistence list. He adds it:

```nix
persistedData = [ 
  "/var/lib/immich"
  "/var/lib/immich/upload"  # Added
];
```

Runs `nix flake check` - passes. Deploys. Service recovers. Total time: 10 minutes, one file edited, complete understanding of what changed. He goes back to sleep.

**This journey reveals requirements for:**
- Single-file service definition (everything in one place)
- Clear, discoverable configuration structure
- Helpful error messages pointing to exact problem
- Fast debugging without jumping between files

### Journey 4: AI Agent - Understanding Strange's Infrastructure

An AI agent is helping Strange add a new service called Miniflux (RSS reader). The agent has never seen this NixOS configuration before and needs to understand the patterns quickly.

**In the current system:**

The agent reads `modules/server/misc/miniflux/default.nix` - sees service configuration. Reads the module, but where's persistence? Where are backups declared? How does Traefik routing work? The agent searches for "persistence", finds declarations scattered across multiple files. Each service seems to do it differently. The agent makes educated guesses, probably forgets something.

**With the new system:**

The agent opens any existing service file, like `modules/server/dns/default.nix`:

```nix
qgroget.server.dns = {
  enable = true;
  port = 5053;
  persistedData = [ "/var/lib/dns" ];
  backupDirectories = [ "/var/lib/dns/zones" ];
  exposed = false;
  type = "private";
};
```

The contract is immediately clear. Every service follows this exact pattern. The agent reads the template comments explaining each field. Within minutes, the agent understands:
- What must be declared (enable, port, persistedData, backupDirectories)
- What's optional (exposed, subdomain, type, middlewares)
- How the collector module uses these declarations

The agent creates Miniflux following the pattern:

```nix
qgroget.server.miniflux = {
  enable = true;
  port = 8080;
  persistedData = [ "/var/lib/miniflux" ];
  backupDirectories = [ "/var/lib/miniflux/data" ];
  exposed = true;
  subdomain = "rss";
  type = "private";
  database.enable = true;
};
```

Runs `nix flake check` - it catches that the agent forgot to specify database.name. The agent fixes it, check passes. Service deploys successfully on first try.

**This journey reveals requirements for:**
- Uniform service pattern (every service identical structure)
- Self-documenting contracts with clear field requirements
- Template with explanatory comments
- Validation that teaches correct usage

### Journey Requirements Summary

These journeys reveal the following capability areas needed:

**1. Service Contract System**
- Required fields: enable, port, persistedData, backupDirectories
- Optional fields: exposed, subdomain, type, middlewares, dependsOn, database
- Enforced at build time (evaluation fails if required fields missing)
- Clear documentation/template showing contract structure

**2. Collector Module**
- Aggregates persistence paths from all enabled services
- Aggregates backup directories from all enabled services
- Generates Traefik routing configuration automatically
- Auto-provisions databases based on service declarations
- Validates dependencies (warns if service depends on disabled service)

**3. Build-Time Validation**
- `nix flake check` catches missing required fields
- Clear error messages indicating exactly what's wrong
- Validation prevents deployment of incomplete configuration
- Schema validation ensuring contract conformance

**4. Migration Support**
- Pattern coexistence (old and new patterns work simultaneously)
- Clear migration template/guide
- Non-disruptive migration path
- Validation that doesn't break existing services

**5. Single-File Service Definition**
- All service configuration in one module file
- No scattered declarations across multiple files
- Service-specific config, persistence, backups, routing all together
- Easy to understand complete service picture

**6. Developer Experience**
- Clear service template to copy
- Self-documenting contract structure
- Uniform pattern across all services
- Fast onboarding for new contributors/agents

## Infrastructure-as-Code Specific Requirements

### Technical Architecture Overview

This NixOS server refactoring employs Infrastructure-as-Code best practices with declarative configuration, build-time validation, and type-safe service contracts. The architecture leverages NixOS's module system to enforce correctness while maintaining developer ergonomics.

### Service Contract Implementation

**Module System Features:**
- **Typed Options with Assertions**: Use `types.submodule` with custom assertion functions to enforce required fields
- **Type Safety**: Leverage Nix's type system to catch configuration errors during evaluation
- **Contract Structure**: Define service contract in `modules/server/options.nix` as reusable submodule type

**Example Contract Definition:**
```nix
types.submodule {
  options = {
    enable = lib.mkEnableOption "service";
    port = lib.mkOption { type = types.int; };
    persistedData = lib.mkOption { 
      type = types.listOf types.str;
      # NO default - forces explicit declaration
    };
    backupDirectories = lib.mkOption { 
      type = types.listOf types.str;
      # NO default - forces explicit declaration
    };
  };
}
```

### Migration & Coexistence Strategy

**Pattern Coexistence:**
- **Conditional Module Imports**: Use `lib.optional` to conditionally import old or new pattern modules
- **Feature Flags**: Service declarations control which pattern is active
- **Non-Breaking Migration**: Both patterns can coexist during transition period

**Implementation Approach:**
```nix
imports = [
  ./old-pattern/services.nix  # Legacy services
] ++ (lib.optional (cfg.newPattern.enable) ./new-pattern/collector.nix);
```

### Collector Module Architecture

**Aggregation Strategy:**
- **`lib.filterAttrs`**: Filter to find enabled services from `config.qgroget.server`
- **`lib.mapAttrsToList`**: Transform service configs into aggregated lists
- **Explicit & Readable**: Clear data flow through functional transformations

**Aggregation Logic:**
```nix
let
  enabledServices = lib.filterAttrs 
    (name: cfg: cfg.enable) 
    config.qgroget.server;
  
  persistencePaths = lib.concatLists (
    lib.mapAttrsToList 
      (name: cfg: cfg.persistedData) 
      enabledServices
  );
  
  backupPaths = lib.mapAttrs 
    (name: cfg: { paths = cfg.backupDirectories; })
    (lib.filterAttrs 
      (name: cfg: cfg.backupDirectories != []) 
      enabledServices
    );
```

### Validation & Error Handling

**Build-Time Validation:**
- **Required Field Enforcement**: Evaluation fails if `persistedData` or `backupDirectories` not declared
- **Port Conflict Detection**: Validate no two services use the same port
- **Clear Error Messages**: Include field name + example of correct usage

**Error Message Format:**
```
Error: Service 'paperless' missing required field 'persistedData'

Example:
  qgroget.server.paperless.persistedData = [ "/var/lib/paperless" ];
```

**Validation Scope:**
- ✅ Port conflict detection (prevent duplicate ports)
- ⚠️ Path overlap allowed (intentional for shared directories like media stack)
- ℹ️ Dependency cycles caught by Nix's infinite recursion detection

### Testing Infrastructure

**Three-Layer Testing Strategy:**

1. **NixOS VM Tests**: Runtime validation of service behavior
   - Services start successfully
   - Persistence works across reboots
   - Traefik routing configured correctly
   - Multi-host testing supported

2. **Evaluation Tests**: Build-time validation of collector logic
   - Service contract conformance
   - Collector aggregation correctness
   - Type system validation

3. **Integration Tests**: Cross-service interactions
   - Service dependencies resolve correctly
   - Database provisioning works
   - Backup configurations complete

**Test Execution:**
```bash
# VM tests
nix build .#checks.x86_64-linux.serviceTest

# Evaluation tests
nix flake check

# Integration tests (multi-service scenarios)
nix build .#checks.x86_64-linux.integrationTest
```

### Documentation & Developer Experience

**Documentation Artifacts:**

1. **Service Template**: Annotated template file with inline comments
   ```nix
   # modules/server/_template/default.nix
   qgroget.server.example = {
     enable = true;  # Enable this service
     port = 8080;    # Internal port for service
     
     # REQUIRED: Directories that must persist across reboots
     persistedData = [ "/var/lib/example" ];
     
     # REQUIRED: Directories to include in backups (use [] for no backup)
     backupDirectories = [ "/var/lib/example/data" ];
     
     # ... rest of contract with explanatory comments
   };
   ```

2. **Architecture Decision Record**: Document explaining:
   - Why service-centric architecture
   - Rationale for collector pattern
   - Trade-offs and alternatives considered
   - Migration strategy reasoning

3. **Migration Guide**: Step-by-step guide showing:
   - Before/after examples
   - Common patterns for different service types
   - Troubleshooting common issues

### Configuration Discovery

**Service Visibility:**
- **Source of Truth**: `hosts/Server/settings.nix` shows all enabled services
- **Query Approach**: Read settings file to see `qgroget.server.<name>.enable` flags
- **Build Output**: Nix evaluation shows aggregated configuration in derivation

**Discovery Methods:**
```nix
# In settings.nix - clear list of enabled services
qgroget.server = {
  jellyfin.enable = true;
  immich.enable = true;
  sonarr.enable = true;
  # ... etc
};
```

### Contract Evolution Strategy

**Simplicity Over Complexity:**
- **No Versioning**: Contract has single current version
- **Breaking Changes**: When contract changes, update all services simultaneously
- **Pragmatic Approach**: Internal tool with complete control allows coordinated updates

**Evolution Process:**
1. Update contract in `options.nix`
2. Update all service modules to match new contract
3. Run `nix flake check` to validate all services conform
4. Deploy updated configuration

**Rationale**: Versioning adds complexity without benefit for single-maintainer internal infrastructure. Coordinated updates are simpler and enforce consistency.

### Implementation Considerations

**Development Workflow:**
1. Define service contract with typed options and assertions
2. Implement collector module with aggregation logic
3. Create service template with documentation
4. Migrate one simple service as proof of concept
5. Add validation tests (VM + evaluation + integration)
6. Iterate on remaining services using proven pattern

**Key Technical Decisions:**
- Leverage Nix's lazy evaluation for efficient builds
- Use assertion functions for helpful error messages
- Conditional imports for zero-overhead migration
- Functional transformations for clear data flow
- Explicit over clever for maintainability

## Functional Requirements

### Service Contract Management

- **FR1**: Infrastructure maintainer can define a service with required fields (enable, port, persistedData, backupDirectories)
- **FR2**: Infrastructure maintainer can define a service with optional fields (exposed, subdomain, type, middlewares, dependsOn, database)
- **FR3**: System can enforce required field declaration (build fails if missing)
- **FR4**: Infrastructure maintainer can declare persistence paths for a service in the same file as service configuration
- **FR5**: Infrastructure maintainer can declare backup directories for a service in the same file as service configuration
- **FR6**: Infrastructure maintainer can declare service routing configuration in the same file as service configuration
- **FR7**: Infrastructure maintainer can declare database requirements for a service

### Configuration Aggregation

- **FR8**: System can aggregate persistence paths from all enabled services
- **FR9**: System can aggregate backup directories from all enabled services
- **FR10**: System can generate Traefik routing configuration from enabled services
- **FR11**: System can auto-provision PostgreSQL databases based on service declarations
- **FR12**: System can validate service dependencies at evaluation time
- **FR13**: Infrastructure maintainer can enable/disable services from central settings file

### Build-Time Validation

- **FR14**: System can detect missing required fields before deployment
- **FR15**: System can provide clear error messages with field name and usage examples
- **FR16**: System can detect port conflicts between services
- **FR17**: System can validate service contract conformance via `nix flake check`
- **FR18**: Infrastructure maintainer can validate configuration without deploying

### Service Migration Support

- **FR19**: Infrastructure maintainer can run old and new service patterns simultaneously
- **FR20**: Infrastructure maintainer can migrate a service without disrupting running service
- **FR21**: Infrastructure maintainer can validate new service configuration before cutover
- **FR22**: System can conditionally import modules based on pattern selection

### Testing & Verification

- **FR23**: Infrastructure maintainer can run NixOS VM tests to verify service runtime behavior
- **FR24**: Infrastructure maintainer can run evaluation tests to verify collector logic
- **FR25**: Infrastructure maintainer can run integration tests for cross-service scenarios
- **FR26**: System can verify services start successfully in VM tests
- **FR27**: System can verify persistence works across reboots in VM tests
- **FR28**: System can verify Traefik routing configured correctly in VM tests

### Documentation & Developer Experience

- **FR29**: Infrastructure maintainer can access annotated service template with inline comments
- **FR30**: Infrastructure maintainer can read architecture decision record explaining pattern rationale
- **FR31**: Infrastructure maintainer can follow migration guide with before/after examples
- **FR32**: Infrastructure maintainer can view all enabled services by reading settings file
- **FR33**: Infrastructure maintainer can understand complete service configuration from single file

### Contract Evolution

- **FR34**: Infrastructure maintainer can update service contract definition
- **FR35**: Infrastructure maintainer can update all services to match new contract simultaneously
- **FR36**: System can validate all services conform to current contract

## Non-Functional Requirements

### Maintainability

- **NFR1**: Service module files shall be self-contained with all related configuration in a single file (no cross-file dependencies for understanding service behavior)
- **NFR2**: New contributors shall be able to understand the service pattern from reading one example service module
- **NFR3**: Service contract changes shall require updates to all affected services within one working session (< 4 hours for all 15 services)
- **NFR4**: Adding a new service shall require editing only the new service module file plus enabling it in settings (no scattered configuration updates)

### Reliability

- **NFR5**: Build-time validation shall catch 100% of missing required declarations before deployment
- **NFR6**: Port conflict detection shall prevent duplicate port assignments with clear error messages
- **NFR7**: Service migration shall maintain zero downtime for production services
- **NFR8**: Configuration errors shall be detected at `nix flake check` time, not at runtime
- **NFR9**: Validation shall prioritize thoroughness over speed (comprehensive checks more important than fast builds)

### Developer Experience

- **NFR10**: Build errors shall include field name, error description, and correct usage example
- **NFR11**: Service template shall include inline comments explaining every field
- **NFR12**: Migration guide shall provide before/after examples for common service types
- **NFR13**: Configuration validation feedback shall provide clear, actionable error messages

