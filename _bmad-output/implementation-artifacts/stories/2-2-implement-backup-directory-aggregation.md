---
name: "2-2-implement-backup-directory-aggregation"
description: "Implement Backup Directory Aggregation"
status: ready-for-dev
epic: 2
---

# Story 2.2: Implement Backup Directory Aggregation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure maintainer,
I want the collector to automatically aggregate backup configurations from all enabled services,
So that every service's data is automatically included in backups without manual configuration.

## Acceptance Criteria

1. **Given** services declare `backupPaths = ["/var/lib/service/data"]`
   **When** the collector module evaluates
   **Then** it creates `qgroget.backups.<service>` entries with aggregated paths

2. **Given** the collector aggregates backup configurations
   **When** the backup module (`modules/server/backup/default.nix`) evaluates
   **Then** it receives complete backup configurations and creates restic backup jobs

3. **Given** services with empty `backupPaths` are enabled
   **When** the collector aggregates backup configurations
   **Then** services with empty `backupPaths` are excluded from backup aggregation

4. **Given** a service declares both `dataDir` and `backupPaths`
   **When** paths are aggregated for backups
   **Then** both `dataDir` and `backupPaths` are included in the backup paths list

5. **Given** multiple services declare overlapping backup paths
   **When** the collector aggregates paths
   **Then** paths are deduplicated to avoid backup redundancy

6. **Given** services need systemd units stopped during backup
   **When** the collector creates backup configurations
   **Then** it includes service systemd units in the backup configuration

7. **Given** services specify backup priorities
   **When** the collector aggregates configurations
   **Then** it sets appropriate backup priorities for service ordering

## Tasks / Subtasks

- [x] Task 1: Analyze current backup system architecture (AC: 1, 2)
  - [x] Subtask 1.1: Review existing backup module (`modules/server/backup/default.nix`)
  - [x] Subtask 1.2: Understand `qgroget.backups.<service>` configuration structure
  - [x] Subtask 1.3: Identify backup service registration pattern and required fields

- [x] Task 2: Implement backup service registration aggregation in collector (AC: 1, 3, 4, 5, 6, 7)
  - [x] Subtask 2.1: Add backup aggregation logic to `modules/server/collector.nix`
  - [x] Subtask 2.2: Create `qgroget.backups.<service>` entries from service contracts
  - [x] Subtask 2.3: Map `service.backupPaths` + `service.dataDir` → `backup.paths`
  - [x] Subtask 2.4: Filter out services with empty backup paths
  - [x] Subtask 2.5: Include service systemd units for backup coordination
  - [x] Subtask 2.6: Set backup priorities for proper ordering
  - [x] Subtask 2.7: Deduplicate overlapping paths across services

- [x] Task 3: Integrate with backup module (AC: 2)
  - [x] Subtask 3.1: Ensure collector output integrates with backup module input
  - [x] Subtask 3.2: Verify backup module receives aggregated configurations
  - [x] Subtask 3.3: Test that restic backup jobs are created correctly

- [x] Task 4: Validation and testing (AC: 1, 2, 3, 4, 5, 6, 7)
  - [x] Subtask 4.1: Run `nix flake check` to validate collector.nix syntax
  - [x] Subtask 4.2: Test with multiple enabled services to verify backup registration
  - [x] Subtask 4.3: Test with services with empty backupPaths to verify filtering
  - [x] Subtask 4.4: Verify backup module creates correct restic configurations
  - [x] Subtask 4.5: Run `alejandra .` to format code

## Dev Notes

### Architecture & Design Patterns

**Integration Architecture:**
- Service contracts define `backupPaths` (list of strings)
- Collector aggregates into `qgroget.backups.<service>` attrset
- Backup module consumes `qgroget.backups` and creates restic configurations
- Flow: Service Contract → Collector → `qgroget.backups` → Backup Module → Restic

**Key Design Decisions:**
- Aggregation follows same functional pattern as Story 2.1: `lib.filterAttrs` → `lib.mapAttrsToList` → `lib.flatten` → `lib.unique`
- Creates complete backup service registrations, not just path lists
- Includes systemd unit coordination for services that need stopping during backup
- Sets backup priorities for proper ordering (databases before applications)
- Collector acts as central aggregation point, keeping service modules independent

**Integration Points:**
- Depends on: Service contract from Story 1.1 (`qgroget.serviceModules` with `backupPaths`)
- Creates: `qgroget.backups.<service>` entries consumed by backup module
- Related to: Story 2.1 (similar aggregation pattern) and backup module
- Part of: Collector module expansion for backup management

**Backup Service Registration Structure:**
```nix
qgroget.backups.<service> = {
  paths = [service.dataDir] ++ service.backupPaths;  # Combined paths
  systemdUnits = ["<service>.service"];              # Units to stop
  priority = 100;                                    # Backup ordering
  exclude = [];                                      # Exclude patterns
  preBackup = null;                                  # Pre-backup script
  postBackup = null;                                 # Post-backup script
};
```

### Project Structure Notes

**Primary Files to Create/Modify:**
- `modules/server/collector.nix` - Add backup service registration aggregation (MODIFY)
- `modules/server/backup/default.nix` - Consumes `qgroget.backups` (already exists, no changes needed)
- `modules/server/options.nix` - Service contract and backup options (already exist, no changes needed)

**Related Architecture:**
- Backup System Integration: [_bmad-output/planning-artifacts/architecture.md#Backup-Integration]
- Backup Service Registration: [_bmad-output/planning-artifacts/architecture.md#Backup-Service-Registration]
- Collector Boundary: [_bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- Configuration Aggregation (FR9): [_bmad-output/planning-artifacts/epics.md#Configuration-Aggregation]

**Integration Flow:**
1. Service contracts define `backupPaths`
2. Collector creates `qgroget.backups.<service>` entries
3. Backup module reads `qgroget.backups` and creates restic configurations
4. Restic performs actual backups

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
- [ ] Multiple enabled services create `qgroget.backups.<service>` entries
- [ ] Services with empty `backupPaths` do not create backup entries
- [ ] Both `dataDir` and `backupPaths` are included in backup paths
- [ ] Overlapping paths are deduplicated
- [ ] Backup module receives correct configurations and creates restic jobs
- [ ] Systemd units are included for service coordination during backup
- [ ] Backup priorities are set correctly
- [ ] Code is formatted with `alejandra .`
- [ ] Aggregation logic uses functional approach (no imperative loops)

### Dev Workflow Notes

**Understanding the Architecture:**
1. Review backup module (`modules/server/backup/default.nix`) to understand how it consumes `qgroget.backups`
2. Understand backup service registration structure from `options.nix`
3. Study existing collector persistence aggregation (Story 2.1) as reference pattern
4. Review service contract structure for `backupPaths` field

**Implementation Strategy:**
1. **Inspect**: Read backup module and understand `qgroget.backups` consumption
2. **Extend**: Add backup aggregation function to `modules/server/collector.nix`
3. **Create**: Generate `qgroget.backups.<service>` entries from service contracts
4. **Test**: Verify backup module receives correct configurations

**Common Pitfalls to Avoid:**
- ❌ Do NOT try to configure Restic/Borg directly (backup module handles this)
- ❌ Do NOT aggregate into wrong data structure (must be `qgroget.backups.<service>`)
- ❌ Do NOT forget to include `dataDir` in addition to `backupPaths`
- ❌ Do NOT skip systemd unit coordination for services that need stopping
- ❌ Do NOT use imperative loops (use functional lib functions)
- ❌ Do NOT skip `alejandra .` before commit

**Questions to Resolve During Implementation:**
- What systemd units should be stopped for each service during backup?
- What backup priorities should different service types have?
- Are there services that need pre/post backup scripts?
- How should network-dependent backups be handled?

**Functional Programming Pattern:**
```nix
# Create backup service registrations from service contracts
enabledServices = lib.filterAttrs (name: service: service.enable) config.qgroget.serviceModules;

qgroget.backups = lib.mapAttrs (name: service: {
  paths = [service.dataDir] ++ service.backupPaths;
  systemdUnits = ["${name}.service"];  # Service-specific units to stop
  priority = 100;  # Default priority, can be customized per service type
}) (lib.filterAttrs (name: service: 
  service.backupPaths != [] || service.dataDir != ""
) enabledServices);
```

### Learning from Story 2.1

**Key Learnings from Previous Story (2-1-implement-persistence-path-aggregation):**

1. **Use `lib.mkAfter` for Merging:**
   - CRITICAL: When aggregating paths, use `lib.mkAfter` to merge with existing host configuration
   - Do NOT overwrite existing backup paths defined at host level
   - Example from Story 2.1:
   ```nix
   environment.persistence."/persist".directories = lib.mkAfter uniquePaths;
   ```

2. **Evaluation Testing is Essential:**
   - Create evaluation test in `tests/collector/` for backup aggregation
   - Test verifies aggregation logic without spinning up VMs (fast feedback)
   - Register test in `flake.nix` checks for automatic validation

3. **Functional Approach Works Well:**
   - `lib.filterAttrs` → `lib.mapAttrsToList` → `lib.flatten` → `lib.unique` pipeline is clean and maintainable
   - No imperative loops, pure functional transformations
   - Easy to reason about and test

4. **Code Location:**
   - Aggregation logic goes in `modules/server/collector.nix`
   - Collector already exists from Story 2.1, just add backup aggregation section
   - Follow the same structure as persistence aggregation

5. **Common Issues & Fixes:**
   - Initial implementation might overwrite existing config → Use `lib.mkAfter`
   - Tests must be properly registered in `flake.nix` to be discoverable
   - Deduplication is important for overlapping paths

**Implementation Notes from Story 2.1:**
- Collector module structure is clean with clear comments
- Each aggregation section is self-contained
- TODO comments mark where future aggregations (like this one) should go
- Always run `alejandra .` before committing

### References

**Architecture & Requirements:**
- Backup System Integration: [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Backup-Integration)
- Collector Module: [_bmad-output/planning-artifacts/architecture.md](/_bmad-output/planning-artifacts/architecture.md#Collector-Module)
- Configuration Aggregation (FR9): [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Configuration-Aggregation)
- Technical Infrastructure: [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Technical-Infrastructure)
- Functional Requirements FR9: [_bmad-output/planning-artifacts/epics.md](/_bmad-output/planning-artifacts/epics.md#Functional-Requirements)

**NixOS & Nix Libraries:**
- Nix Library Functions: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library
- Backup Module: [modules/server/backup/default.nix]
- Service Options: [modules/server/options.nix]
- Collector Module: [modules/server/collector.nix]

**Related Stories:**
- Story 1.1: Define Service Contract Schema (dependency - provides service structure)
- Story 2.1: Implement Persistence Path Aggregation (reference implementation - similar aggregation pattern)
- Story 2.3: Implement Traefik Routing Generation (collector module expansion)
- Story 4.1: Create Collector Evaluation Test Framework (testing for this implementation)

**Previous Story Reference:**
- Story 2.1 Implementation: [stories/2-1-implement-persistence-path-aggregation.md]
- Backup Module Architecture: [modules/server/backup/default.nix]

## Dev Agent Record

### Agent Model Used

GitHub Copilot (Claude Sonnet 4)

### Debug Log References

- Created at: 2026-01-10
- Story ID: 2-2
- Epic ID: 2
- Related: bmm-workflow-status.yaml, sprint-status.yaml
- Backup aggregation implementation successful
- All tests passing with nix flake check

### Completion Notes List

- [x] Backup directory aggregation implemented in collector.nix
- [x] qgroget.backups.<service> entries created correctly
- [x] Service filtering (enabled services with backupPaths) working
- [x] Path aggregation (dataDir + backupPaths) functional
- [x] SystemdUnits integration for service coordination
- [x] Backup priorities set correctly (100 default)
- [x] Test framework validates all acceptance criteria
- [x] nix flake check passes completely
- [x] Code formatted with alejandra

### File List

Files created/modified during implementation:
- `modules/server/collector.nix` (backup aggregation logic added)
- `tests/collector/backup-eval-test.nix` (comprehensive backup test)
- `flake.nix` (test integration added)
