---
name: "2-1-implement-persistence-path-aggregation"
description: "Implement Persistence Path Aggregation"
status: done
epic: 2
---

# Story 2.1: Implement Persistence Path Aggregation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure maintainer,
I want the collector to automatically aggregate persistence paths from all enabled services,
So that I don't have to manually maintain a separate persistence configuration.

## Acceptance Criteria

1. **Given** multiple services are enabled with `dataDir` and `backupPaths` declared
   **When** the collector module evaluates
   **Then** it aggregates all persistence paths using `lib.filterAttrs` and `lib.mapAttrsToList`

2. **Given** services with persistence configuration
   **When** the collector aggregates paths
   **Then** the aggregated paths are available for the Impermanence module in the correct format

3. **Given** some services are enabled and some are disabled
   **When** the collector module evaluates
   **Then** paths from disabled services are not included in the aggregation

4. **Given** a service declares both `dataDir` and `backupPaths`
   **When** the collector aggregates paths
   **Then** both types of paths are collected and deduplicated if overlapping

## Tasks / Subtasks

- [x] Task 1: Analyze current persistence configuration (AC: 1, 2)
  - [x] Subtask 1.1: Review existing Impermanence configuration in `modules/server/`
  - [x] Subtask 1.2: Identify current pattern for defining persistence paths
  - [x] Subtask 1.3: Understand required format for `environment.persistence."/persist".directories`

- [x] Task 2: Implement persistence path aggregation in collector (AC: 1, 2, 3)
  - [x] Subtask 2.1: Add aggregation logic to `modules/server/collector.nix`
  - [x] Subtask 2.2: Use `lib.filterAttrs` to filter only enabled services
  - [x] Subtask 2.3: Use `lib.mapAttrsToList` to extract `dataDir` and `backupPaths` from each service
  - [x] Subtask 2.4: Flatten and deduplicate the resulting list of paths

- [x] Task 3: Integrate with Impermanence module (AC: 2)
  - [x] Subtask 3.1: Create output attribute in collector module for persistence paths
  - [x] Subtask 3.2: Wire collector output to Impermanence configuration
  - [x] Subtask 3.3: Test that format matches `environment.persistence."/persist".directories` requirements

- [x] Task 4: Implement filtering and deduplication (AC: 3, 4)
  - [x] Subtask 4.1: Ensure disabled services are excluded from aggregation
  - [x] Subtask 4.2: Handle overlapping paths between `dataDir` and `backupPaths`
  - [x] Subtask 4.3: Use `lib.unique` or similar to deduplicate paths

- [x] Task 5: Validation and testing (AC: 1, 2, 3, 4)
  - [x] Subtask 5.1: Run `nix flake check` to validate collector.nix syntax
  - [x] Subtask 5.2: Test with multiple enabled services to verify aggregation
  - [x] Subtask 5.3: Test with disabled services to verify filtering
  - [x] Subtask 5.4: Verify Impermanence module receives correct configuration

## Dev Notes

### Architecture & Design Patterns

This story implements the first aggregation function of the collector module. It's critical for the **Configuration Aggregation** capability, enabling automatic persistence management without manual configuration.

**Key Design Decisions:**
- Aggregation happens at evaluation time (not runtime)
- Uses functional programming approach: `lib.filterAttrs` → `lib.mapAttrsToList` → `lib.flatten` → `lib.unique`
- Collector module acts as central aggregation point, keeping service modules independent
- Output format must match Impermanence expectations: list of directory paths

**Integration Points:**
- Depends on: Service contract from Story 1.1 (`qgroget.serviceModules` with `dataDir` and `backupPaths`)
- Consumed by: Impermanence module via `environment.persistence."/persist".directories`
- Related to: Story 2.2 (Backup Directory Aggregation) - similar pattern but different output format
- Part of: Collector module implementation pattern [Source: _bmad-output/planning-artifacts/architecture.md#Collector-Module]

### Project Structure Notes

**Primary Files to Create/Modify:**
- `modules/server/collector.nix` - Main aggregation logic (NEW or MODIFY)
- `modules/server/default.nix` - Import collector and wire to Impermanence (MODIFY)
- `modules/server/options.nix` - Service contract (already exists from Story 1.1)

**Related Architecture:**
- Impermanence integration: [Source: _bmad-output/planning-artifacts/architecture.md#Impermanence-Integration]
- Collector boundary: [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- Configuration Aggregation (FR8): [Source: _bmad-output/planning-artifacts/epics.md#Configuration-Aggregation]

**Alignment with 11 Consistency Rules:**
1. ✅ Module files: Using `modules/server/collector.nix` (Pattern 1)
2. N/A Service contracts: Already defined in Story 1.1 (Pattern 2)
3. N/A Database names: Not applicable to this story (Pattern 3)
4. N/A SOPS secrets: Not applicable to this story (Pattern 4)
5. ✅ Module structure: Collector is separate from service modules (Pattern 5)
6. N/A Test organization: VM tests come in Epic 4 (Pattern 6)
7. N/A Traefik middleware: Story 2.3 (Pattern 7)
8. N/A Database connections: Story 2.4 (Pattern 8)
9. N/A Container abstraction: Service-level concern (Pattern 9)
10. ✅ Code formatting: Must run `alejandra .` before commit (Pattern 10)
11. N/A Migration commits: Applies to Epic 5 (Pattern 11)

### Testing Standards Summary

**Validation Checklist Before Completion:**
- [ ] `nix flake check` passes with no errors
- [ ] Multiple enabled services have their paths aggregated correctly
- [ ] Disabled services do not contribute paths to aggregation
- [ ] Overlapping paths are deduplicated
- [ ] Impermanence module receives paths in correct format
- [ ] Code is formatted with `alejandra .`
- [ ] Aggregation logic uses functional approach (no imperative loops)

### Dev Workflow Notes

**Understanding the Architecture:**
1. Review the Impermanence integration pattern [Source: _bmad-output/planning-artifacts/architecture.md#Impermanence-Integration]
2. Understand the collector module boundary [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
3. Study existing Impermanence configuration in the codebase
4. Review service contract from Story 1.1 (`qgroget.serviceModules` structure)

**Implementation Strategy:**
1. **Inspect**: Find current Impermanence configuration to understand format
2. **Create/Extend**: Add or extend `modules/server/collector.nix` with aggregation function
3. **Wire**: Connect collector output to Impermanence module input
4. **Test**: Verify with `nix flake check` and evaluate aggregation output

**Common Pitfalls to Avoid:**
- ❌ Do NOT aggregate at runtime (must be evaluation-time)
- ❌ Do NOT include paths from disabled services
- ❌ Do NOT use imperative loops (use functional lib functions)
- ❌ Do NOT forget to deduplicate paths
- ❌ Do NOT skip `alejandra .` before commit
- ❌ Do NOT break existing Impermanence configuration

**Questions to Resolve During Implementation:**
- What is the current Impermanence configuration structure?
- Does `modules/server/collector.nix` already exist from Story 1.1?
- Are there existing services with `dataDir` or `backupPaths` to test with?
- What is the exact format expected by `environment.persistence."/persist".directories`?

**Key Functional Programming Patterns:**
```nix
# Pattern for aggregation:
enabledServices = lib.filterAttrs (name: service: service.enable) cfg.serviceModules;
persistencePaths = lib.flatten (lib.mapAttrsToList (name: service: 
  [ service.dataDir ] ++ service.backupPaths
) enabledServices);
uniquePaths = lib.unique persistencePaths;
```

### References

**Architecture & Requirements:**
- Impermanence Integration: [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Impermanence-Integration)
- Collector Module: [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Collector-Module)
- Configuration Aggregation (FR8): [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Configuration-Aggregation)
- Technical Infrastructure: [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Technical-Infrastructure)
- Functional Requirements FR8: [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Functional-Requirements)

**NixOS & Nix Libraries:**
- Nix Library Functions: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library
- Impermanence Module: https://github.com/nix-community/impermanence
- NixOS Module Options: https://nixos.org/manual/nixos/unstable/index.html#sec-writing-modules

**Related Stories:**
- Story 1.1: Define Service Contract Schema (dependency - provides service structure)
- Story 2.2: Implement Backup Directory Aggregation (similar aggregation pattern)
- Story 2.3: Implement Traefik Routing Generation (collector module expansion)
- Story 4.2: Create Collector Evaluation Test Framework (testing for this implementation)

## Dev Agent Record

### Agent Model Used

GitHub Copilot - Claude Sonnet 4.5

### Debug Log References

- Created at: 2026-01-10
- Story ID: 2-1
- Epic ID: 2
- Related: bmm-workflow-status.yaml, sprint-status.yaml

### Completion Notes List

Task 1 Analysis Findings:

Subtask 1.1: Existing Impermanence configurations found in:
- modules/server/settings.nix: Uses lib.concatLists with lib.mapAttrsToList on config.qgroget.services, extracting service.persistedData
- modules/server/misc/forgero.nix: Defines environment.persistence."/persist".directories = [ "${config.services.forgejo.stateDir}" ]
- modules/server/collector.nix: Placeholder with comment about aggregating persistence paths

Subtask 1.2: Current patterns:
- Old: qgroget.services.*.persistedData (single path string)
- New: Per-service modules define their own persistence (like forgero)
- Future: Aggregate from qgroget.serviceModules.*.dataDir and backupPaths

Subtask 1.3: Format for environment.persistence."/persist".directories:
- List of strings (absolute paths)
- Can also be attribute sets: { directory = "/path"; user = "owner"; group = "group"; }
- For aggregation, collect as list of strings

Task 2 Implementation:
Implemented persistence path aggregation in modules/server/collector.nix using functional approach:
- lib.filterAttrs to select enabled services from config.qgroget.serviceModules
- lib.mapAttrsToList to extract [dataDir] ++ backupPaths from each service
- lib.flatten to combine all path lists
- lib.unique to deduplicate overlapping paths

Task 3 Integration:
Collector outputs directly to environment.persistence."/persist".directories, integrating with Impermanence module automatically.
CRITICAL FIX: Uses lib.mkAfter to merge with existing host persistence config instead of overwriting.

Task 4 Filtering/Deduplication:
- Disabled services excluded via enable filter
- Paths deduplicated with lib.unique

Task 5 Validation:
- nix flake check passes with no errors
- Created tests/collector/eval-test.nix for evaluation testing
- Test properly registered in flake.nix checks.collectorPersistenceTest
- Test verifies directory creation and disabled service exclusion
- Code formatted with alejandra

### File List

- modules/server/collector.nix - Persistence aggregation logic with lib.mkAfter
- tests/collector/eval-test.nix - Evaluation test for aggregation (registered in flake.nix)
- flake.nix - Added collectorPersistenceTest to checks

### Change Log

- Implemented persistence path aggregation in collector module (Story 2.1)
- Fixed collector to use lib.mkAfter to avoid overwriting existing host persistence config
- Registered test in flake.nix checks for proper validation
- Fixed test implementation to verify persistence behavior correctly
