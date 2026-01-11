# Story 1.5: Create Module Entry Point with Imports

Status: done

## Story

As an infrastructure maintainer,
I want a clean module entry point that imports the contract and collector,
So that the server module system is properly organized and discoverable.

## Acceptance Criteria

1. **Given** the file [modules/server/default.nix](../../modules/server/default.nix) exists
   **When** I import the server module
   **Then** it imports:
   - `./options.nix` (service contract)
   - `./collector.nix` (aggregation logic - TO BE CREATED)
   - Individual service modules as needed
   **And** the module is importable without errors
   **And** the structure follows Pattern 1 (module file naming)

2. **Given** the collector.nix module does not yet exist
   **When** I create the module entry point
   **Then** the import for `./collector.nix` is added to `default.nix`
   **And** a placeholder `collector.nix` file is created with empty implementation
   **And** the placeholder has clear comments indicating it will be implemented in Epic 2

3. **Given** the current `default.nix` already contains assertion logic for required field validation
   **When** I reorganize the module entry point
   **Then** the assertion logic is preserved (from Story 1.3 and 1.4)
   **And** the module remains backwards-compatible with existing service imports
   **And** all existing functionality continues to work

## Tasks / Subtasks

- [x] Task 1: Review current default.nix structure (AC: 1, 3)
  - [x] Subtask 1.1: Read current [modules/server/default.nix](../../modules/server/default.nix) completely
  - [x] Subtask 1.2: Document existing imports and assertion logic
  - [x] Subtask 1.3: Identify what needs to be preserved vs reorganized

- [x] Task 2: Create placeholder collector.nix (AC: 2)
  - [x] Subtask 2.1: Create [modules/server/collector.nix](../../modules/server/collector.nix)
  - [x] Subtask 2.2: Add module header with clear documentation
  - [x] Subtask 2.3: Add comment explaining this is a placeholder for Epic 2
  - [x] Subtask 2.4: Add empty config section to make it a valid NixOS module
  - [x] Subtask 2.5: Document what the collector will eventually do (aggregation logic)

- [x] Task 3: Update default.nix imports (AC: 1, 2, 3)
  - [x] Subtask 3.1: Ensure `./options.nix` is imported (already present)
  - [x] Subtask 3.2: Add `./collector.nix` to imports list
  - [x] Subtask 3.3: Keep existing service module imports (media, arrs, downloaders, etc.)
  - [x] Subtask 3.4: Keep existing assertion logic for required field validation
  - [x] Subtask 3.5: Add header comments explaining module organization

- [x] Task 4: Validate module structure (AC: 1, 2, 3)
  - [x] Subtask 4.1: Run `nix flake check` to ensure no evaluation errors
  - [x] Subtask 4.2: Verify existing services still work (no regression)
  - [x] Subtask 4.3: Verify assertion logic still triggers for missing required fields
  - [x] Subtask 4.4: Run `alejandra .` to format all Nix code
  - [x] Subtask 4.5: Final `nix flake check` to confirm everything passes

## Dev Notes

### Architecture Context

This story completes **Epic 1: Core Service Contract Infrastructure** by organizing the module entry point and preparing for Epic 2's aggregation logic.

**Key architectural goals:**
1. **Clear module organization** - The `default.nix` file serves as the entry point that imports all core components
2. **Separation of concerns** - Contract definition (`options.nix`), aggregation logic (`collector.nix`), and validation (assertions in `default.nix`)
3. **Forward compatibility** - Placeholder collector.nix allows Epic 2 to implement aggregation without changing module structure
4. **Backwards compatibility** - Existing service imports and assertion logic must continue working

### Relevant Architecture Patterns

From [architecture.md](../../_bmad-output/planning-artifacts/architecture.md):

**Pattern 1: Module file naming**
- Core module files use `default.nix` as entry point
- Service contracts defined in `options.nix`
- Aggregation logic in `collector.nix`
- Service-specific modules in subdirectories with `default.nix`

**Module Organization:**
```
modules/server/
├── default.nix       # Module entry point (THIS STORY)
├── options.nix       # Service contract definition (Story 1.1)
├── collector.nix     # Aggregation logic (Epic 2 - placeholder for now)
├── settings.nix      # Service enablement settings
└── <category>/       # Service-specific modules
    └── <service>/
        └── default.nix
```

**Three-layer architecture:**
1. **Contract layer** (`options.nix`) - Define service schema, enforce types
2. **Aggregation layer** (`collector.nix`) - Aggregate configurations from enabled services
3. **Service layer** (individual service modules) - Service-specific implementation

### Current State Analysis

Based on stories 1.1-1.4, the following is already implemented:

**Story 1.1**: Service contract schema in [options.nix](../../modules/server/options.nix)
- `qgroget.serviceModules` with required fields: `enable`, `domain`, `dataDir`
- Optional fields: `extraConfig`, `middleware`, `databases`, `backupPaths`

**Story 1.2**: Annotated service template in [_template/default.nix](../../modules/server/_template/default.nix)
- Three-section structure (contract, implementation, secrets)
- Comprehensive inline documentation
- Example values for all fields

**Story 1.3**: Required field enforcement in [default.nix](../../modules/server/default.nix)
- Assertion logic using `lib.mapAttrsToList` to iterate over all services
- Validates presence of required fields when `enable = true`
- Errors fail at evaluation time (not runtime)

**Story 1.4**: Clear error messages with examples in [default.nix](../../modules/server/default.nix)
- Error format includes: service name, field names, usage examples
- Follows NFR10 requirements for actionable error messages
- Shows concrete fix example for each missing field

**Current [default.nix](../../modules/server/default.nix) structure** (lines 1-61):
```nix
{
  config,
  lib,
  ...
}: {
  imports = [
    ./options.nix
    ./settings.nix
    ./media
    ./arrs
    # ./security
    ./downloaders
    ./traefik
    ./dashboard
    ./password-manager
    ./dns
    ./SSO
    ./backup
    ./misc
    # ./homeAssistant
  ];

  config = {
    # Validation: Ensure all enabled services have required fields
    assertions = lib.flatten (lib.mapAttrsToList (
      serviceName: serviceConfig: let
        isEnabled = serviceConfig.enable or false;
        hasDomain = serviceConfig.domain or null != null;
        hasDataDir = serviceConfig.dataDir or null != null;
        missingFields =
          []
          ++ (lib.optional (!hasDomain) "domain")
          ++ (lib.optional (!hasDataDir) "dataDir");
        missingFieldsStr = lib.concatStringsSep ", " missingFields;
      in
        if isEnabled && missingFields != []
        then [
          {
            assertion = false;
            message = ''
              Service '${serviceName}' is enabled but missing required field(s): ${missingFieldsStr}

              Configuration Error:
              When qgroget.serviceModules.${serviceName}.enable = true, you must provide:
              ${lib.optionalString (!hasDomain) "  - domain (string): Domain name for the service (e.g., \"${serviceName}.example.com\")"}
              ${lib.optionalString (!hasDataDir) "  - dataDir (string): Data directory path for persistent data (e.g., \"/var/lib/${serviceName}\")"}

              Example fix:
              qgroget.serviceModules.${serviceName} = {
                enable = true;
                domain = "${serviceName}.example.com";
                dataDir = "/var/lib/${serviceName}";
              };
            '';
          }
        ]
        else []
    )
    config.qgroget.serviceModules);
  };
}
```

### What Needs to Change

**Minimal changes for this story:**

1. **Add collector.nix to imports** - Just add `./collector.nix` to the imports list
2. **Create placeholder collector.nix** - Empty module with documentation comments
3. **Add header comments** - Explain the module organization pattern

**What to preserve:**
- All existing imports (service modules, settings, options)
- All assertion logic from stories 1.3 and 1.4
- Current module structure and functionality

**What NOT to implement (Epic 2):**
- Aggregation logic (persistence paths, backup directories, Traefik routing)
- Database auto-provisioning
- Service dependency validation
- Port conflict detection across services

### Project Structure Notes

**Files to modify:**
1. [modules/server/default.nix](../../modules/server/default.nix) - Add collector import, add header comments
2. [modules/server/collector.nix](../../modules/server/collector.nix) - Create new file (placeholder)

**Pattern conformance:**
- Follows Pattern 1: Module file naming convention
- Follows NFR1: Self-contained module organization
- Follows architectural boundary: Clear separation between contract, aggregation, and services

**Integration points:**
- Imports `options.nix` (service contract) - Already present
- Imports `collector.nix` (aggregation logic) - Add in this story
- Imports individual service modules - Already present
- Provides assertion-based validation - Already present

### Testing Strategy

**Validation steps:**
1. Run `nix flake check` - Must pass without errors
2. Test assertion logic - Create test service with missing required field, verify error message
3. Test existing services - Ensure no regression in currently configured services
4. Test collector import - Verify empty collector.nix doesn't break evaluation

**Expected outcomes:**
- Module evaluates successfully
- Existing services continue to work
- Assertion logic still triggers for missing fields
- No functional changes to service behavior (aggregation comes in Epic 2)

### References

**Architecture documents:**
- [architecture.md](../../_bmad-output/planning-artifacts/architecture.md) - Module organization patterns
- [epics.md](../../_bmad-output/planning-artifacts/epics.md) - Story 1.5 requirements and acceptance criteria
- [prd.md](../../_bmad-output/planning-artifacts/prd.md) - NFR1-NFR4 (maintainability requirements)

**Completed stories:**
- [Story 1.1](./1-1-define-service-contract-schema.md) - Service contract schema in options.nix
- [Story 1.2](./1-2-create-annotated-service-template.md) - Annotated service template
- [Story 1.3](../../_bmad-output/implementation-artifacts/1-3-implement-required-field-enforcement.md) - Required field enforcement
- [Story 1.4](../../_bmad-output/implementation-artifacts/1-4-implement-clear-error-messages-with-examples.md) - Clear error messages

**Source files:**
- [modules/server/default.nix](../../modules/server/default.nix) - Current module entry point
- [modules/server/options.nix](../../modules/server/options.nix) - Service contract definition
- [modules/server/_template/default.nix](../../modules/server/_template/default.nix) - Service template

## Dev Agent Record

### Agent Model Used

GitHub Copilot (Grok Code Fast 1) - AI programming assistant following NixOS service contract migration patterns.

### Debug Log References

- Initial review: Confirmed existing default.nix structure with imports and assertion logic
- Created collector.nix placeholder with comprehensive documentation
- Updated default.nix imports to include collector.nix after options.nix
- Added module organization header comments
- Validation: nix flake check passed, alejandra formatting successful

### Completion Notes List

1. **Module Structure Established**: Created clean three-part import structure (options.nix → collector.nix → service modules)
2. **Placeholder Implementation**: collector.nix serves as forward-compatible stub for Epic 2 aggregation logic
3. **Backwards Compatibility**: All existing imports and assertion logic preserved
4. **Validation Success**: No evaluation errors, formatting compliant, existing functionality intact
5. **Documentation**: Added clear header comments explaining module organization and purpose

### File List

**Modified Files:**
- [modules/server/default.nix](../../modules/server/default.nix) - Added collector.nix import and header comments
- [_bmad-output/implementation-artifacts/stories/1-5-create-module-entry-point-with-imports.md](../../_bmad-output/implementation-artifacts/stories/1-5-create-module-entry-point-with-imports.md) - Updated status and tasks

**Created Files:**
- [modules/server/collector.nix](../../modules/server/collector.nix) - Placeholder module for Epic 2 aggregation logic

### Change Log

- **2026-01-09**: Completed implementation of Story 1.5
  - Created placeholder collector.nix with Epic 2 documentation
  - Updated default.nix imports and added organization comments
  - Validated with nix flake check and alejandra formatting
  - All acceptance criteria satisfied, story marked complete
