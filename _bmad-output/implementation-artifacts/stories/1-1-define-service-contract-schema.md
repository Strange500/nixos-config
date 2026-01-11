# Story 1.1: Define Service Contract Schema

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure maintainer,
I want a typed service contract definition with required and optional fields,
So that I have a clear, enforceable structure for all service declarations.

## Acceptance Criteria

1. **Given** the file `modules/server/options.nix` exists
   **When** I define a service under `qgroget.serviceModules.<service>`
   **Then** the system provides typed options for required fields: `enable`, `domain`, `dataDir`

2. **Given** services are defined with the contract
   **When** I check the contract definition
   **Then** the system provides typed options for optional fields: `extraConfig`, `middleware`, `databases`, `backupPaths`

3. **Given** a service module with `enable = true`
   **When** I omit a required field (e.g., `dataDir`)
   **Then** `nix flake check` fails with a clear error message identifying the missing field

4. **Given** the service contract implementation
   **When** I evaluate the flake
   **Then** the schema uses `types.submodule` for type safety ensuring all fields are properly typed

## Tasks / Subtasks

- [x] Task 1: Set up module entry point structure (AC: 1, 2, 4)
  - [x] Subtask 1.1: Review `modules/server/` directory structure
  - [x] Subtask 1.2: Create `modules/server/options.nix` file if not exists
  - [x] Subtask 1.3: Define base `qgroget.serviceModules` namespace using `types.submodule`
  
- [x] Task 2: Implement required field contract (AC: 1, 3, 4)
  - [x] Subtask 2.1: Define `enable` field (type: bool, required)
  - [x] Subtask 2.2: Define `domain` field (type: string, required)
  - [x] Subtask 2.3: Define `dataDir` field (type: string, required)
  - [x] Subtask 2.4: Implement assertion to fail if required fields are missing

- [x] Task 3: Implement optional field contract (AC: 2, 4)
  - [x] Subtask 3.1: Define `extraConfig` field (type: attrs, optional)
  - [x] Subtask 3.2: Define `middleware` field (type: list of strings, optional)
  - [x] Subtask 3.3: Define `databases` field (type: list of strings, optional)
  - [x] Subtask 3.4: Define `backupPaths` field (type: list of strings, optional)

- [x] Task 4: Implement error handling (AC: 3)
  - [x] Subtask 4.1: Create assertion that validates all required fields are set
  - [x] Subtask 4.2: Generate error message with field name, service name, and example usage
  - [x] Subtask 4.3: Test error messages follow format: `qgroget.serviceModules.<service>.<field> = <example>;`

- [x] Task 5: Validation and testing (AC: 1, 2, 3, 4)
  - [x] Subtask 5.1: Run `nix flake check` to validate options.nix syntax
  - [x] Subtask 5.2: Test that service contract can be imported from flake.nix
  - [x] Subtask 5.3: Verify type checking works correctly
  - [x] Subtask 5.4: Verify required field enforcement works

## Dev Notes

### Architecture & Design Patterns

This story establishes the foundation for the entire service module refactoring. The service contract uses the **flat structure pattern** with `types.submodule` at service level (NOT nested groups). This is critical for the collector module to work correctly.

**Key Design Decisions:**
- Flat namespace: `qgroget.serviceModules.jellyfin` (NOT `qgroget.serviceModules.media.jellyfin`)
- Uses Nix type system: `types.submodule` for contract definition
- Required fields: `enable`, `domain`, `dataDir` - no defaults (forces explicit declaration)
- Optional fields: `extraConfig`, `middleware`, `databases`, `backupPaths`
- Evaluation-time validation: Assertions must fail at build time, not runtime

**Integration Points:**
- This contract will be aggregated by `modules/server/collector.nix` (Story 2.1+)
- The contract is imported by `modules/server/default.nix` (Story 1.5)
- Error messages must follow NFR10 requirements with examples [Source: _bmad-output/planning-artifacts/epics.md#Non-Functional-Requirements]

### Project Structure Notes

**Primary Files to Create/Modify:**
- `modules/server/options.nix` - Main contract definition (NEW)
- `modules/server/default.nix` - Module entry point that imports options.nix (may exist)
- `flake.nix` - Ensure server module is imported in flake configuration (MODIFY)

**Related Architecture:**
- Service contract pattern: [Source: _bmad-output/planning-artifacts/architecture.md#Service-Contract-Pattern]
- Pattern 1-4: Module file naming and service contract names [Source: _bmad-output/planning-artifacts/architecture.md#Implementation-Patterns]
- Type system enforcement: [Source: _bmad-output/planning-artifacts/architecture.md#NixOS-Module-System-Constraints]

**Alignment with 11 Consistency Rules:**
1. ✅ Module files: `modules/server/` directory structure (Pattern 1)
2. ✅ Service contracts: Flat `qgroget.serviceModules.<service>` (Pattern 2)
3. N/A Database names: Explicit declaration (Pattern 3)
4. N/A SOPS secrets: "server/<service>/<secret-name>" (Pattern 4)
5. ✅ Module structure: Three-section pattern (start of Pattern 5)
6. N/A Test organization: Per-service tests (Pattern 6)
7. N/A Traefik middleware: Predefined names (Pattern 7)
8. N/A Database connections: Systemd credentials (Pattern 8)
9. N/A Container abstraction: (Pattern 9)
10. ✅ Code formatting: Must run `alejandra .` before commit (Pattern 10)
11. N/A Migration commits: Applies to migration phase (Pattern 11)

### Testing Standards Summary

**Validation Checklist Before Completion:**
- [ ] `nix flake check` passes with no errors
- [ ] All required fields throw errors when omitted
- [ ] Error messages include: field name, service name, example usage
- [ ] Optional fields can be omitted without error
- [ ] Type checking prevents invalid values (e.g., enable must be bool)
- [ ] Code is formatted with `alejandra .`
- [ ] Service contract can be imported in flake.nix without errors

### Dev Workflow Notes

**Understanding the Architecture:**
1. Read the service contract pattern explanation [Source: _bmad-output/planning-artifacts/architecture.md#Service-Contract-Pattern]
2. Review the validation requirements [Source: _bmad-output/planning-artifacts/architecture.md#Validation-Requirements-MANDATORY]
3. Check the implementation patterns [Source: _bmad-output/planning-artifacts/architecture.md#Implementation-Patterns-11-Consistency-Rules]
4. Review current server module structure in `modules/server/`

**Common Pitfalls to Avoid:**
- ❌ Do NOT create nested service groups (use flat structure only)
- ❌ Do NOT add defaults to required fields (forces explicit declaration)
- ❌ Do NOT use runtime assertions (must be evaluation-time)
- ❌ Do NOT skip error message examples (all assertions must include usage example)
- ❌ Do NOT forget to run `alejandra .` before commit

**Questions to Resolve During Implementation:**
- Does `modules/server/` already exist? If so, review its current structure
- Are there existing service options that should be consolidated into this contract?
- Should the contract support nested attributes for complex configuration?
- What is the complete list of supported middleware names for validation? (needed for Story 3.3)

### References

**Architecture & Requirements:**
- Service Contract Pattern: [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Service-Contract-Pattern)
- Implementation Patterns (11 Rules): [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Implementation-Patterns-11-Consistency-Rules)
- Validation Requirements: [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Validation-Requirements-MANDATORY)
- Functional Requirements FR1-FR7: [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Service-Contract-Management)
- Non-Functional Requirement NFR1, NFR4, NFR10, NFR11: [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Non-Functional-Requirements)

**NixOS Module System:**
- NixOS Module System Guide: https://nixos.org/manual/nixos/unstable/index.html#ch-writing-modules
- Nix Type System: https://nixos.org/manual/nix/unstable/language/advanced-attributes.html

**Related Stories:**
- Story 1.2: Create Annotated Service Template (depends on 1.1)
- Story 1.5: Create Module Entry Point with Imports (depends on 1.1)
- Story 2.1: Implement Persistence Path Aggregation (depends on 1.1)

## Dev Agent Record

### Agent Model Used

GitHub Copilot - Claude Haiku 4.5

### Debug Log References

- Created at: 2026-01-08
- Story ID: 1-1
- Epic ID: 1
- Related: bmm-workflow-status.yaml, sprint-status.yaml

### Completion Notes List

**IMPLEMENTATION COMPLETE - 2026-01-08**

Implemented Service Contract Schema with all acceptance criteria met:

1. ✅ Created `qgroget.serviceModules` namespace with `types.submodule` pattern
   - Flat structure (not nested groups) for integration with collector module
   - Required fields: `enable` (bool), `domain` (string), `dataDir` (string)
   - Optional fields: `extraConfig` (attrs), `middleware` (list), `databases` (list), `backupPaths` (list)

2. ✅ Implemented type safety and validation
   - All fields properly typed using Nix type system
   - Assertions enforce required fields when service is enabled
   - Clear error messages with concrete examples show correct usage pattern

3. ✅ Validation and testing completed
   - `nix flake check` passes without type errors
   - Service contract evaluates correctly: `qgroget.serviceModules` resolves to attributes
   - Integration verified: Server host configuration imports `modules/server` correctly
   - Type enforcement validated: `nix eval` confirms schema structure

4. ✅ Code formatted with `alejandra`
   - `modules/server/default.nix` formatted
   - Code follows project style guidelines

### File List

Files created/modified during implementation:

- **`modules/server/options.nix`** (MODIFIED)
  - Added new `qgroget.serviceModules` namespace with flat structure pattern
  - Added required fields: `enable`, `domain`, `dataDir`
  - Added optional fields: `extraConfig`, `middleware`, `databases`, `backupPaths`

- **`modules/server/default.nix`** (MODIFIED)
  - Added config section with assertions for required field validation
  - Implements clear error messages showing correct usage examples
  - Validation logic uses `lib.mapAttrsToList` and `lib.flatten` for evaluation-time checks

**Expected files (already exist, no modifications needed):**
- `flake.nix` - Server module automatically imported via `hosts/Server/configuration.nix`

### Change Log

| Date | Event | Details |
|------|-------|---------|
| 2026-01-08 | Implementation Complete | Service contract schema fully implemented and validated |
| 2026-01-08 | Code Formatting | Ran `alejandra` on modified files |
| 2026-01-08 | Validation Complete | `nix flake check` passed, type safety verified |
| 2026-01-08 | Story Status Updated | Status changed from `ready-for-dev` to `done` |
