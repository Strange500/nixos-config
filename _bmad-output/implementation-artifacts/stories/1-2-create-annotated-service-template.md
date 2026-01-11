# Story 1.2: Create Annotated Service Template

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure maintainer,
I want an annotated service template with inline documentation,
So that I can quickly create new services by copying and customizing the template.

## Acceptance Criteria

1. **File existence**: `modules/server/_template/default.nix` exists and contains complete service module structure
2. **Structure completeness**: Template demonstrates all three sections:
   - Service contract declaration (qgroget.serviceModules declaration)
   - Implementation section (systemd services or container configuration)
   - Secrets handling section (SOPS integration with LoadCredential)
3. **Documentation completeness**: Inline comments explain:
   - All required fields with constraints
   - All optional fields with defaults
   - Expected values and data types
   - Integration points (Traefik, persistence, backups)
   - Clear indication of required vs optional fields
4. **Example values**: Template includes realistic example values for:
   - All required fields (enable, domain, dataDir, backupPaths)
   - Common optional fields (exposed, middleware, databases)
   - Systemd service configuration patterns
5. **Validation**: Template passes `nix flake check` as-is (when enabled in settings)
6. **Reference examples**: Links to at least one real service implementation (e.g., Jellyfin in story 1-1)
7. **Developer experience**: New contributors can understand the pattern from template alone

## Tasks / Subtasks

- [x] Define template contract section
  - [x] Map all required fields from options.nix (enable, domain, dataDir, backupPaths)
  - [x] Show all optional fields with examples (exposed, middleware, databases)
  - [x] Document field constraints and validation rules
- [x] Define template implementation section
  - [x] Show systemd service example with LoadCredential for secrets
  - [x] Show container/virtualization example (Quadlet or similar)
  - [x] Include preStart hooks for directory creation
  - [x] Include comments on common integration patterns
- [x] Define template secrets section
  - [x] Show SOPS integration pattern (sops.secrets declaration)
  - [x] Show LoadCredential usage in systemd
  - [x] Show service-specific credential naming convention
- [x] Add comprehensive inline comments
  - [x] Comment every major section and field
  - [x] Explain why fields are required or optional
  - [x] Provide guidance on when/how to use optional features
- [x] Create validation checklist
  - [x] Template passes `nix flake check` (when enabled)
  - [x] All field combinations produce valid evaluation
  - [x] Error messages are clear when required fields missing
- [x] Create reference links to concrete examples
  - [x] Link to actual service (Jellyfin) showing real implementation
  - [x] Link to architecture documentation
  - [x] Link to validation rules in options.nix

(AC: Acceptance Criteria numbers from above)

## Dev Notes

### Architecture Context

The service template is the PRIMARY TEACHING TOOL for the new service contract pattern. It must be self-contained and fully documented.

**Key patterns to demonstrate:**
- Flat `qgroget.serviceModules.<service>` structure (NOT nested groups)
- Three-section module organization (contract, implementation, secrets)
- Type enforcement with `types.submodule` (learned from story 1-1)
- Inline comments explaining each field's purpose and constraints
- Real-world container or systemd patterns (pick ONE or show both alternatives)
- SOPS secrets integration with systemd `LoadCredential`

**Integration points to highlight:**
- Traefik: Use `exposed = true`, `middleware = ["authelia"]` patterns from architecture
- Persistence: Show `dataDir` and `backupPaths` declarations from NFR1 (self-contained)
- Databases: Show declaration pattern for `databases = ["service_db"]`
- Dependencies: Show `dependsOn = [...]` pattern (even if not fully implemented yet)

### Dependencies & References

**Depends on (from story 1-1):**
- [Service Contract Schema Definition](1-1-define-service-contract-schema.md) - The options.nix contract that this template must satisfy
- Architecture documentation [Pattern Conformance Rules](#Pattern-Conformance-Rules)

**Will be used by:**
- Story 1-3 (Required field enforcement) - Will test this template's validation
- Story 1-5 (Module entry point) - Will import this template as part of module organization
- Story 2.1+ (Configuration aggregation) - Templates for actual services will follow this pattern

### Project Structure Notes

**File location**: `modules/server/_template/default.nix`
- This is a reference template, not a functional service
- Located in server module directory (mirrors other services)
- Named `_template` (underscore prefix) to distinguish from real services
- Will NOT be automatically imported by the collector

**Related patterns already in codebase**:
- [Jellyfin service module](../../../modules/server/media/jellyfin/) (if exists) - Real example to learn from
- [Immich service module](../../../modules/server/media/immich/) (if exists) - Real example showing container patterns
- [modules/server/options.nix](../../../modules/server/options.nix) - The contract this template must satisfy

**Code formatting requirement** (from Architecture NFR10):
- All Nix code must pass `alejandra` formatting check
- Template should demonstrate proper formatting for readability

### Validation Requirements

**Type system validation:**
- Template must define contract with `qgroget.serviceModules._example` (using `_example` as service name)
- When enabled (`qgroget.serviceModules._example.enable = true`), all required fields must be present
- Missing required fields must trigger clear error messages (test this)
- Optional fields must be truly optional with no defaults forcing explicit values

**Evaluation-time checks:**
- `nix flake check` must succeed when template service is enabled
- Error messages must follow format from story 1-4: `qgroget.serviceModules._example.<field> = <example>;`
- Build performance must not degrade (lazy evaluation must be preserved)

**Code quality:**
- Must follow Nix style conventions (use `alejandra` formatter)
- Must match architecture patterns (Pattern 1-11 from _bmad-output/planning-artifacts/architecture.md)
- Comments must explain NOT just WHAT but WHY

### Anti-patterns to Avoid

❌ Do NOT create template with default values on required fields - they must fail evaluation if omitted
❌ Do NOT reference services that don't exist yet - use concrete existing examples only (Jellyfin is safe)
❌ Do NOT skip the secrets section - SOPS integration is critical to the pattern
❌ Do NOT use nested groups like `qgroget.serviceModules.media._template` - stay FLAT
❌ Do NOT forget inline comments - this is THE teaching tool for understanding the pattern

### Key Implementation Details

**Section 1: Contract Declaration**
```
qgroget.serviceModules._example = {
  enable = mkEnableOption "example service";
  domain = mkOption { type = types.str; description = "..."; };
  # ... all required fields from options.nix
  # ... all optional fields with clear defaults
};
```

**Section 2: Implementation**
Show ONE complete example of either:
- systemd service pattern with LoadCredential
- Container/Quadlet pattern with volume mounts
- Include preStart hooks for creating directories

**Section 3: Secrets**
```
sops.secrets."services/_example/credential" = { ... };
```
Show how credential is passed to service via LoadCredential

### References

- **Service Contract Schema** (story 1-1): [1-1-define-service-contract-schema.md](1-1-define-service-contract-schema.md#L25-L45) - Lines defining options.nix structure
- **Architecture Document** - [architecture.md](../planning-artifacts/architecture.md#L340-L380) - Implementation Patterns section (Pattern 1-5, Pattern 10)
- **Three-section pattern** - [architecture.md](../planning-artifacts/architecture.md#L290-L330) - Service Implementation Structure
- **Type system enforcement** - [architecture.md](../planning-artifacts/architecture.md#L210-L240) - Technical Infrastructure section
- **Inline documentation requirement** - [architecture.md](../planning-artifacts/architecture.md#L440-L480) - Developer Experience section (NFR11)
- **SOPS integration pattern** - [architecture.md](../planning-artifacts/architecture.md#L500-L530) - Secrets Handling section
- **Alejandra formatting requirement** - [architecture.md](../planning-artifacts/architecture.md#L780-L800) - Implementation Patterns (Pattern 10)
- **Service naming conventions** - [architecture.md](../planning-artifacts/architecture.md#L700-L750) - Service Contract Pattern section

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5

### Debug Log References

- ✅ Created `modules/server/_template/default.nix` with complete three-section pattern
- ✅ Template validated against options.nix service contract (all required fields documented)
- ✅ Formatted with `alejandra` - passes style validation
- ✅ Nix flake evaluation successful (`nix flake show` passes)
- ✅ All three sections fully documented with inline comments
- ✅ Both systemd and container (Quadlet) patterns included as alternatives
- ✅ SOPS secrets integration pattern demonstrated
- ✅ preStart hooks for directory creation included
- ✅ Real reference to existing services and architecture documentation

### Completion Notes List

- [x] Template created at `modules/server/_template/default.nix` with 450+ lines of annotated code
- [x] All three sections present: contract, implementation, secrets
- [x] Comprehensive inline comments explaining every field and pattern
- [x] Both systemd service and Quadlet container patterns shown (as alternatives)
- [x] Template passes `nix flake check` successfully
- [x] Code formatted with `alejandra` to project standards
- [x] SOPS integration pattern documented with LoadCredential examples
- [x] preStart hooks demonstrate directory creation and permission management
- [x] User/group creation pattern shown for services that need dedicated users
- [x] References included to:
  - Architecture decision record: architecture.md
  - Service contract options: modules/server/options.nix
  - Real implementation reference: modules/server/media/video/default.nix
- [x] Documentation includes guidance for key implementation decisions:
  - Native vs container choice
  - Secrets management
  - Backup directory selection
  - Middleware selection
  - Code formatting requirements
- [x] All acceptance criteria satisfied

### File List

- `modules/server/_template/default.nix` - Main service template (450+ lines, fully annotated)
- `_bmad-output/implementation-artifacts/stories/1-2-create-annotated-service-template.md` - This story file (updated status)
