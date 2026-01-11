---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
workflowType: 'epics-and-stories'
project_name: 'nixos'
user_name: 'Strange'
date: '2026-01-08'
lastStep: 4
status: 'complete'
completedAt: '2026-01-08'
---

# nixos - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for nixos, decomposing the requirements from the PRD and Architecture documents into implementable stories.

## Requirements Inventory

### Functional Requirements

**Service Contract Management:**
- FR1: Infrastructure maintainer can define a service with required fields (enable, port, persistedData, backupDirectories)
- FR2: Infrastructure maintainer can define a service with optional fields (exposed, subdomain, type, middlewares, dependsOn, database)
- FR3: System can enforce required field declaration (build fails if missing)
- FR4: Infrastructure maintainer can declare persistence paths for a service in the same file as service configuration
- FR5: Infrastructure maintainer can declare backup directories for a service in the same file as service configuration
- FR6: Infrastructure maintainer can declare service routing configuration in the same file as service configuration
- FR7: Infrastructure maintainer can declare database requirements for a service

**Configuration Aggregation:**
- FR8: System can aggregate persistence paths from all enabled services
- FR9: System can aggregate backup directories from all enabled services
- FR10: System can generate Traefik routing configuration from enabled services
- FR11: System can auto-provision PostgreSQL databases based on service declarations
- FR12: System can validate service dependencies at evaluation time
- FR13: Infrastructure maintainer can enable/disable services from central settings file

**Build-Time Validation:**
- FR14: System can detect missing required fields before deployment
- FR15: System can provide clear error messages with field name and usage examples
- FR16: System can detect port conflicts between services
- FR17: System can validate service contract conformance via `nix flake check`
- FR18: Infrastructure maintainer can validate configuration without deploying

**Service Migration Support:**
- FR19: Infrastructure maintainer can run old and new service patterns simultaneously
- FR20: Infrastructure maintainer can migrate a service without disrupting running service
- FR21: Infrastructure maintainer can validate new service configuration before cutover
- FR22: System can conditionally import modules based on pattern selection

**Testing & Verification:**
- FR23: Infrastructure maintainer can run NixOS VM tests to verify service runtime behavior
- FR24: Infrastructure maintainer can run evaluation tests to verify collector logic
- FR25: Infrastructure maintainer can run integration tests for cross-service scenarios
- FR26: System can verify services start successfully in VM tests
- FR27: System can verify persistence works across reboots in VM tests
- FR28: System can verify Traefik routing configured correctly in VM tests

**Documentation & Developer Experience:**
- FR29: Infrastructure maintainer can access annotated service template with inline comments
- FR30: Infrastructure maintainer can read architecture decision record explaining pattern rationale
- FR31: Infrastructure maintainer can follow migration guide with before/after examples
- FR32: Infrastructure maintainer can view all enabled services by reading settings file
- FR33: Infrastructure maintainer can understand complete service configuration from single file

**Contract Evolution:**
- FR34: Infrastructure maintainer can update service contract definition
- FR35: Infrastructure maintainer can update all services to match new contract simultaneously
- FR36: System can validate all services conform to current contract

### Non-Functional Requirements

**Maintainability:**
- NFR1: Service module files shall be self-contained with all related configuration in a single file (no cross-file dependencies for understanding service behavior)
- NFR2: New contributors shall be able to understand the service pattern from reading one example service module
- NFR3: Service contract changes shall require updates to all affected services within one working session (< 4 hours for all 15 services)
- NFR4: Adding a new service shall require editing only the new service module file plus enabling it in settings (no scattered configuration updates)

**Reliability:**
- NFR5: Build-time validation shall catch 100% of missing required declarations before deployment
- NFR6: Port conflict detection shall prevent duplicate port assignments with clear error messages
- NFR7: Service migration shall maintain zero downtime for production services
- NFR8: Configuration errors shall be detected at `nix flake check` time, not at runtime
- NFR9: Validation shall prioritize thoroughness over speed (comprehensive checks more important than fast builds)

**Developer Experience:**
- NFR10: Build errors shall include field name, error description, and correct usage example
- NFR11: Service template shall include inline comments explaining every field
- NFR12: Migration guide shall provide before/after examples for common service types
- NFR13: Configuration validation feedback shall provide clear, actionable error messages

### Additional Requirements from Architecture

**Technical Infrastructure:**
- Core module infrastructure with options.nix (service contract using types.submodule) and collector.nix (aggregation logic)
- Service template pattern at modules/server/_template/default.nix with annotated examples
- Three-section service module structure: contract declaration, implementation, SOPS secrets
- Type system enforcement with no defaults on required fields (forces explicit declaration)
- Functional aggregation using lib.filterAttrs and lib.mapAttrsToList for clarity

**Validation & Error Handling:**
- Evaluation-time assertions for port conflicts with clear error messages including examples
- Dependency validation throwing errors (not warnings) for missing service dependencies
- Database name uniqueness validation across all services
- Middleware name validation against predefined map
- All validation must occur at evaluation time, not runtime

**Integration Requirements:**
- Traefik dynamic configuration generation from service declarations (exposed, subdomain, type, middlewares)
- Impermanence module integration for persistence path aggregation
- Restic/Borg backup system integration for backup directory aggregation
- PostgreSQL database auto-provisioning with connection details exposed back to services
- SOPS secrets integration following "server/<service>/<credential-type>" naming pattern

**Testing Infrastructure:**
- Three-layer testing: NixOS VM tests (runtime behavior), evaluation tests (collector logic), integration tests (cross-service scenarios)
- Per-service test directory structure: tests/<service>/default.nix for VM tests
- Collector-specific tests in tests/collector/ for aggregation logic validation
- All tests exposed via flake checks output

**Migration Strategy:**
- Pattern coexistence via conditional module imports (old and new patterns work simultaneously)
- Four-phase migration approach: Core Infrastructure → Proof of Concept → Full Migration → Cleanup
- Non-disruptive incremental migration (one service at a time, each independently deployable)
- Migration commit convention with standard format and checklist
- Zero downtime requirement for family-used services (Jellyfin, Immich, Vaultwarden)

**Implementation Patterns (11 Consistency Rules):**
- Pattern 1: Module files use default.nix at modules/server/<category>/<service>/default.nix
- Pattern 2: Service contract name matches directory name
- Pattern 3: Database names explicitly set and validated for uniqueness
- Pattern 4: SOPS secrets follow "server/<service>/<credential-type>" hierarchy
- Pattern 5: Three-section service module structure (contract, implementation, secrets)
- Pattern 6: Per-service test directory with standardized file names
- Pattern 7: Predefined Traefik middleware names validated at evaluation time
- Pattern 8: Database connection information as structured data (not pre-formatted strings)
- Pattern 9: Container vs native service abstraction (identical contract regardless)
- Pattern 10: Alejandra code formatter enforced (run before commits)
- Pattern 11: Migration commit convention with standard checklist

**Architectural Boundaries:**
- Contract boundary (options.nix): Define schema, enforce types, no aggregation
- Collector boundary (collector.nix): Aggregate data, validate business rules, generate configs
- Service module boundary: Service-specific logic, SOPS secrets, systemd/container config
- Test boundary: VM tests (runtime), eval tests (build-time), integration tests (cross-service)

### FR Coverage Map

**Service Contract Management:**
- FR1: Epic 1 - Infrastructure maintainer can define a service with required fields
- FR2: Epic 1 - Infrastructure maintainer can define a service with optional fields
- FR3: Epic 1 - System can enforce required field declaration
- FR4: Epic 1 - Infrastructure maintainer can declare persistence paths in same file
- FR5: Epic 1 - Infrastructure maintainer can declare backup directories in same file
- FR6: Epic 1 - Infrastructure maintainer can declare service routing in same file
- FR7: Epic 1 - Infrastructure maintainer can declare database requirements

**Configuration Aggregation:**
- FR8: Epic 2 - System can aggregate persistence paths from all enabled services
- FR9: Epic 2 - System can aggregate backup directories from all enabled services
- FR10: Epic 2 - System can generate Traefik routing configuration from enabled services
- FR11: Epic 2 - System can auto-provision PostgreSQL databases based on declarations
- FR12: Epic 2 - System can validate service dependencies at evaluation time
- FR13: Epic 2 - Infrastructure maintainer can enable/disable services from central settings

**Build-Time Validation:**
- FR14: Epic 1 - System can detect missing required fields before deployment
- FR15: Epic 1 - System can provide clear error messages with usage examples
- FR16: Epic 3 - System can detect port conflicts between services
- FR17: Epic 1, Epic 3 - System can validate service contract conformance via nix flake check
- FR18: Epic 2 - Infrastructure maintainer can validate configuration without deploying

**Service Migration Support:**
- FR19: Epic 5 - Infrastructure maintainer can run old and new patterns simultaneously
- FR20: Epic 5 - Infrastructure maintainer can migrate service without disrupting running service
- FR21: Epic 5 - Infrastructure maintainer can validate new configuration before cutover
- FR22: Epic 5 - System can conditionally import modules based on pattern selection

**Testing & Verification:**
- FR23: Epic 4 - Infrastructure maintainer can run NixOS VM tests for runtime behavior
- FR24: Epic 4 - Infrastructure maintainer can run evaluation tests for collector logic
- FR25: Epic 4 - Infrastructure maintainer can run integration tests for cross-service scenarios
- FR26: Epic 4 - System can verify services start successfully in VM tests
- FR27: Epic 4 - System can verify persistence works across reboots in VM tests
- FR28: Epic 4 - System can verify Traefik routing configured correctly in VM tests

**Documentation & Developer Experience:**
- FR29: Epic 1 - Infrastructure maintainer can access annotated service template
- FR30: Epic 6 - Infrastructure maintainer can read architecture decision record
- FR31: Epic 6 - Infrastructure maintainer can follow migration guide with examples
- FR32: Epic 6 - Infrastructure maintainer can view all enabled services by reading settings
- FR33: Epic 6 - Infrastructure maintainer can understand complete service from single file
- FR34: Epic 1 - Infrastructure maintainer can update service contract definition
- FR35: Epic 6 - Infrastructure maintainer can update all services to match new contract
- FR36: Epic 1, Epic 3 - System can validate all services conform to current contract

## Epic List

### Epic 1: Core Service Contract Infrastructure
**What infrastructure maintainers can accomplish:** Define service contracts with required fields, get immediate build-time validation, and use a clear template for any service. This is the foundation that makes everything else possible.

**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR14, FR15, FR17, FR29, FR34, FR36  
**NFRs covered:** NFR1, NFR2, NFR4, NFR10, NFR11  
**Additional:** Core module structure (options.nix, collector.nix, _template/), type system enforcement, three-section pattern, alejandra formatting

---

### Epic 2: Configuration Aggregation & Integration
**What infrastructure maintainers can accomplish:** Enable services and have the system automatically handle persistence, backups, Traefik routing, and database provisioning. No more scattered configuration across multiple files.

**FRs covered:** FR8, FR9, FR10, FR11, FR12, FR13, FR18  
**NFRs covered:** NFR5, NFR8, NFR9, NFR13  
**Additional:** Traefik integration, Impermanence integration, Backup system integration, PostgreSQL provisioning, SOPS secrets pattern

---

### Epic 3: Validation & Error Detection System
**What infrastructure maintainers can accomplish:** Catch all configuration errors at build time with clear, actionable error messages that show exactly how to fix issues. Zero configuration problems reach production.

**FRs covered:** FR16, FR17 (expanded validation), FR36 (contract conformance)  
**NFRs covered:** NFR5, NFR6, NFR8, NFR9, NFR10, NFR13  
**Additional:** Port conflict detection, dependency validation, database name validation, middleware validation, evaluation-time assertions

---

### Epic 4: Testing Infrastructure
**What infrastructure maintainers can accomplish:** Verify services work correctly through automated VM tests, evaluation tests, and integration tests. Confidence that passing tests means working services.

**FRs covered:** FR23, FR24, FR25, FR26, FR27, FR28  
**NFRs covered:** NFR5, NFR8, NFR9  
**Additional:** Three-layer testing (VM, eval, integration), per-service test structure, collector tests

---

### Epic 5: Service Migration Support
**What infrastructure maintainers can accomplish:** Migrate existing services to the new pattern incrementally, one at a time, with zero downtime. Old and new patterns coexist safely during migration.

**FRs covered:** FR19, FR20, FR21, FR22  
**NFRs covered:** NFR3, NFR7  
**Additional:** Pattern coexistence, conditional imports, migration commit convention, proof-of-concept service

---

### Epic 6: Documentation & Developer Experience
**What infrastructure maintainers can accomplish:** Onboard quickly with clear documentation, understand the architecture, and follow proven migration patterns. AI agents and humans can contribute confidently.

**FRs covered:** FR30, FR31, FR32, FR33, FR35  
**NFRs covered:** NFR2, NFR12  
**Additional:** Architecture decision record, migration guide, inline template documentation

---

### Epic 7: Full Service Migration
**What infrastructure maintainers can accomplish:** All 15+ services migrated to the new pattern, operating with consistent configuration, full backup coverage, and clean codebase ready for future additions.

**FRs covered:** All FRs (implementation across all services)  
**NFRs covered:** NFR3, NFR7  
**Additional:** Migration of Jellyfin, Immich, *arr services, Traefik, Authelia, LLDAP, Vaultwarden, etc.

---

## Epic 1: Core Service Contract Infrastructure

**Epic Goal:** Define service contracts with required fields, get immediate build-time validation, and use a clear template for any service. This is the foundation that makes everything else possible.

### Story 1.1: Define Service Contract Schema

As an infrastructure maintainer,
I want a typed service contract definition with required and optional fields,
So that I have a clear, enforceable structure for all service declarations.

**Acceptance Criteria:**

**Given** the file `modules/server/options.nix` exists
**When** I define a service under `qgroget.serviceModules.<service>`
**Then** the system provides typed options for:
- Required: `enable`, `domain`, `dataDir`
- Optional: `extraConfig`, `middleware`, `databases`, `backupPaths`
**And** omitting required fields causes evaluation to fail with a clear error message
**And** the schema uses `types.submodule` for type safety

---

### Story 1.2: Create Annotated Service Template

As an infrastructure maintainer,
I want an annotated service template with inline documentation,
So that I can quickly create new services by copying and customizing the template.

**Acceptance Criteria:**

**Given** the file `modules/server/_template/default.nix` exists
**When** I read the template
**Then** I see:
- Complete three-section structure (contract, implementation, secrets)
- Inline comments explaining each field
- Example values for all required and optional fields
- Clear indication of which fields are required vs optional
**And** the template passes `nix flake check` as-is (disabled by default)

---

### Story 1.3: Implement Required Field Enforcement

As an infrastructure maintainer,
I want build failures when required fields are missing,
So that I cannot accidentally deploy a misconfigured service.

**Acceptance Criteria:**

**Given** a service module with `enable = true`
**When** I omit `dataDir` (a required field)
**Then** `nix flake check` fails with error message containing:
- The field name that is missing
- The service name
- An example of correct usage
**And** the error occurs at evaluation time (not runtime)

---

### Story 1.4: Implement Clear Error Messages with Examples

As an infrastructure maintainer,
I want error messages that show me exactly how to fix issues,
So that I can quickly resolve configuration problems without searching documentation.

**Acceptance Criteria:**

**Given** a service with a configuration error (e.g., missing required field)
**When** I run `nix flake check`
**Then** the error message includes:
- Field name and service name
- Description of what's wrong
- Concrete example showing correct usage
- Format: `qgroget.serviceModules.<service>.<field> = <example>;`
**And** error messages follow NFR10 requirements

---

### Story 1.5: Create Module Entry Point with Imports

As an infrastructure maintainer,
I want a clean module entry point that imports the contract and collector,
So that the server module system is properly organized and discoverable.

**Acceptance Criteria:**

**Given** the file `modules/server/default.nix` exists
**When** I import the server module
**Then** it imports:
- `./options.nix` (service contract)
- `./collector.nix` (aggregation logic)
- Individual service modules as needed
**And** the module is importable without errors
**And** the structure follows Pattern 1 (module file naming)

---

## Epic 2: Configuration Aggregation & Integration

**Epic Goal:** Enable services and have the system automatically handle persistence, backups, Traefik routing, and database provisioning. No more scattered configuration across multiple files.

### Story 2.1: Implement Persistence Path Aggregation

As an infrastructure maintainer,
I want the collector to automatically aggregate persistence paths from all enabled services,
So that I don't have to manually maintain a separate persistence configuration.

**Acceptance Criteria:**

**Given** multiple services are enabled with `dataDir` and `backupPaths` declared
**When** the collector module evaluates
**Then** it aggregates all persistence paths using `lib.filterAttrs` and `lib.mapAttrsToList`
**And** the aggregated paths are available for the Impermanence module
**And** paths from disabled services are not included

---

### Story 2.2: Implement Backup Directory Aggregation

As an infrastructure maintainer,
I want the collector to automatically aggregate backup directories from all enabled services,
So that every service's data is automatically included in backups without manual configuration.

**Acceptance Criteria:**

**Given** services declare `backupPaths = ["/var/lib/service/data"]`
**When** the collector module evaluates
**Then** it creates a combined list of all backup paths
**And** the backup system (Restic/Borg) receives the aggregated paths
**And** services with empty `backupPaths` are excluded from backup aggregation

---

### Story 2.3: Implement Traefik Routing Generation

As an infrastructure maintainer,
I want Traefik routing configuration automatically generated from service declarations,
So that I don't need to manually configure routing for each exposed service.

**Acceptance Criteria:**

**Given** a service with `exposed = true`, `subdomain = "jellyfin"`, `type = "public"`
**When** the collector module evaluates
**Then** it generates Traefik dynamic configuration with:
- Router rule for the subdomain
- Service pointing to the correct port
- Middleware chain based on `type` (public/private)
**And** services with `exposed = false` get no Traefik configuration
**And** the generated config integrates with existing Traefik setup

---

### Story 2.4: Implement PostgreSQL Database Auto-Provisioning

As an infrastructure maintainer,
I want PostgreSQL databases automatically provisioned based on service declarations,
So that I don't need to manually create databases for each service.

**Acceptance Criteria:**

**Given** a service declares `databases = [{ type = "postgresql"; name = "immich"; user = "immich"; }]`
**When** the collector module evaluates
**Then** it configures PostgreSQL to:
- Create the database with the specified name
- Create the user with appropriate permissions
- Expose connection details back to the service module
**And** the service module can access `databaseConfig.host`, `databaseConfig.port`, etc.

---

### Story 2.5: Implement Dependency Validation at Evaluation Time

As an infrastructure maintainer,
I want service dependencies validated at evaluation time,
So that I get immediate feedback if a service depends on another that isn't enabled.

**Acceptance Criteria:**

**Given** a service declares `dependsOn = ["postgresql"]`
**When** the dependent service is not enabled
**Then** `nix flake check` fails with error:
- "Service 'immich' depends on 'postgresql' which is not enabled"
- Example showing how to enable the dependency
**And** validation occurs at evaluation time (not runtime)

---

### Story 2.6: Implement Central Service Enablement

As an infrastructure maintainer,
I want to enable/disable services from a central settings file,
So that I can see all enabled services in one place.

**Acceptance Criteria:**

**Given** the file `hosts/Server/settings.nix` exists
**When** I set `qgroget.serviceModules.jellyfin.enable = true`
**Then** the service is activated and included in collector aggregation
**And** all enabled services are visible by reading the settings file
**And** disabled services are excluded from all aggregations

---

## Epic 3: Validation & Error Detection System

**Epic Goal:** Catch all configuration errors at build time with clear, actionable error messages that show exactly how to fix issues. Zero configuration problems reach production.

### Story 3.1: Implement Port Conflict Detection

As an infrastructure maintainer,
I want the system to detect port conflicts between services,
So that I catch deployment issues before they cause runtime failures.

**Acceptance Criteria:**

**Given** two services both declare `port = 8080`
**When** I run `nix flake check`
**Then** evaluation fails with error message:
- "Port 8080 conflict between 'jellyfin' and 'sonarr'"
- "Fix: qgroget.serviceModules.sonarr.port = 8081;"
**And** the check uses evaluation-time assertions
**And** all services are checked for conflicts (not just pairs)

---

### Story 3.2: Implement Database Name Uniqueness Validation

As an infrastructure maintainer,
I want database names validated for uniqueness across all services,
So that I don't accidentally create conflicting database configurations.

**Acceptance Criteria:**

**Given** two services declare databases with the same name
**When** I run `nix flake check`
**Then** evaluation fails with error:
- "Duplicate database name 'mydb' declared by 'service1' and 'service2'"
- Example showing how to fix with unique names
**And** validation occurs at evaluation time

---

### Story 3.3: Implement Middleware Name Validation

As an infrastructure maintainer,
I want middleware names validated against a predefined list,
So that I catch typos in middleware configuration before deployment.

**Acceptance Criteria:**

**Given** a service declares `middlewares = ["auth-sso"]`
**When** "auth-sso" is not in the predefined middleware map
**Then** `nix flake check` fails with error:
- "Unknown middleware 'auth-sso' in service 'jellyfin'"
- "Valid middlewares: authentik, chain-authelia, rate-limit, ..."
**And** the middleware map is defined in collector.nix

---

### Story 3.4: Implement Contract Conformance Validation

As an infrastructure maintainer,
I want all services validated for contract conformance,
So that I can be confident every service follows the required pattern.

**Acceptance Criteria:**

**Given** multiple services defined under `qgroget.serviceModules`
**When** I run `nix flake check`
**Then** all services are checked for:
- Required fields present
- Field types correct
- No unknown fields
**And** violations produce clear error messages with examples
**And** a single check validates all services

---

## Epic 4: Testing Infrastructure

**Epic Goal:** Verify services work correctly through automated VM tests, evaluation tests, and integration tests. Confidence that passing tests means working services.

### Story 4.1: Create Collector Evaluation Test Framework

As an infrastructure maintainer,
I want evaluation tests that validate collector aggregation logic,
So that I can verify the collector works correctly without spinning up VMs.

**Acceptance Criteria:**

**Given** the file `tests/collector/eval-test.nix` exists
**When** I run `nix flake check`
**Then** the test validates:
- Persistence paths are correctly aggregated
- Backup directories are correctly aggregated
- Traefik config is correctly generated
- Database provisioning config is correct
**And** tests run quickly (no VM required)
**And** tests are exposed via flake `checks` output

---

### Story 4.2: Create Per-Service VM Test Structure

As an infrastructure maintainer,
I want a standard structure for per-service VM tests,
So that I can verify services start and function correctly in isolation.

**Acceptance Criteria:**

**Given** the directory structure `tests/<service>/default.nix`
**When** I create a new service VM test
**Then** I follow the standard structure:
- NixOS VM test using `nixosTest` framework
- Service starts successfully
- Basic functionality verified
- Test exposed via flake `checks.<system>.<service>Test`
**And** existing tests (jellyfin, jellyseerr) follow this structure

---

### Story 4.3: Implement Service Startup Verification Test

As an infrastructure maintainer,
I want VM tests that verify services start successfully,
So that I can catch startup issues before deploying to production.

**Acceptance Criteria:**

**Given** a service VM test exists
**When** the test runs
**Then** it verifies:
- systemd service reaches "active" state
- Service responds on configured port
- No critical errors in service logs
**And** test failures provide clear diagnostics

---

### Story 4.4: Implement Persistence Verification Test

As an infrastructure maintainer,
I want VM tests that verify persistence works across reboots,
So that I can be confident data survives server restarts.

**Acceptance Criteria:**

**Given** a service with persistence configured
**When** the VM test runs
**Then** it:
- Creates test data in persisted directory
- Reboots the VM
- Verifies test data still exists after reboot
**And** test covers the Impermanence integration

---

### Story 4.5: Implement Traefik Routing Verification Test

As an infrastructure maintainer,
I want tests that verify Traefik routing is configured correctly,
So that I can be confident services are accessible via their subdomains.

**Acceptance Criteria:**

**Given** a service with `exposed = true` and a subdomain
**When** the integration test runs
**Then** it verifies:
- Traefik has the expected router configuration
- Request to subdomain routes to correct backend
- Middleware chain is applied correctly
**And** test uses the collector-generated Traefik config

---

### Story 4.6: Create Integration Test for Cross-Service Scenarios

As an infrastructure maintainer,
I want integration tests for multi-service scenarios,
So that I can verify services work together correctly.

**Acceptance Criteria:**

**Given** the file `tests/integration/<scenario>.nix` exists
**When** I run the integration test
**Then** it verifies cross-service interactions:
- Service dependencies are satisfied
- Database connections work
- Authentication flows complete (e.g., Authelia + LLDAP)
**And** test is exposed via flake `checks` output

---

## Epic 5: Service Migration Support

**Epic Goal:** Migrate existing services to the new pattern incrementally, one at a time, with zero downtime. Old and new patterns coexist safely during migration.

### Story 5.1: Implement Pattern Coexistence via Conditional Imports

As an infrastructure maintainer,
I want old and new service patterns to work simultaneously,
So that I can migrate services incrementally without breaking existing ones.

**Acceptance Criteria:**

**Given** some services use old `qgroget.services` pattern and some use new `qgroget.serviceModules` pattern
**When** I build the system
**Then** both patterns function correctly
**And** the collector only aggregates from the new pattern services
**And** old pattern services continue using their existing configuration locations
**And** no build errors or conflicts between patterns

---

### Story 5.2: Create Proof-of-Concept Service Migration

As an infrastructure maintainer,
I want to migrate one simple service as proof of concept,
So that I can validate the migration pattern before migrating critical services.

**Acceptance Criteria:**

**Given** a simple service (e.g., Portfolio or DNS) using the old pattern
**When** I migrate it to the new pattern
**Then** I:
- Create the new service module following the template
- Enable the new pattern in settings.nix
- Disable the old pattern
- Verify service continues working
**And** the migration serves as a reference for all future migrations
**And** the migration follows commit convention (Pattern 11)

---

### Story 5.3: Implement Pre-Cutover Validation

As an infrastructure maintainer,
I want to validate new service configuration before switching over,
So that I can catch issues without disrupting the running service.

**Acceptance Criteria:**

**Given** a service migrated to the new pattern but not yet enabled
**When** I run `nix flake check`
**Then** the new configuration is validated:
- Contract fields are correct
- Collector aggregation includes the service (when enabled)
- No conflicts with other services
**And** I can enable the new pattern with confidence
**And** the old pattern remains active until explicit cutover

---

### Story 5.4: Implement Zero-Downtime Migration Process

As an infrastructure maintainer,
I want to migrate services without any downtime,
So that family-used services (Jellyfin, Immich) remain available during migration.

**Acceptance Criteria:**

**Given** a critical service like Jellyfin needs migration
**When** I follow the migration process
**Then**:
- Old service continues running during migration
- New configuration is validated before cutover
- Cutover happens in a single `nixos-rebuild switch`
- Service interruption is only the normal rebuild time (seconds)
**And** rollback is possible by reverting the git commit

---

### Story 5.5: Document Migration Commit Convention

As an infrastructure maintainer,
I want a standard commit message format for migrations,
So that migration history is clear and follows consistent patterns.

**Acceptance Criteria:**

**Given** the migration commit convention (Pattern 11)
**When** I migrate a service
**Then** I use commit format:
- `refactor(server/<service>): migrate to service contract`
- Body lists: contract definition, collector integration, VM test, old pattern removal
- Includes checklist of completed items
**And** commit message follows the standard template

---

## Epic 6: Documentation & Developer Experience

**Epic Goal:** Onboard quickly with clear documentation, understand the architecture, and follow proven migration patterns. AI agents and humans can contribute confidently.

### Story 6.1: Create Architecture Decision Record

As an infrastructure maintainer or contributor,
I want a comprehensive architecture decision record,
So that I understand the rationale behind the service contract design.

**Acceptance Criteria:**

**Given** the file `docs/architecture-decision-record.md` exists
**When** I read the document
**Then** I understand:
- Why flat service contract structure was chosen
- Why automatic collector activation was chosen
- Rationale for evaluation-time validation
- Trade-offs considered for each decision
**And** the document references the planning artifacts for full context

---

### Story 6.2: Create Migration Guide with Before/After Examples

As an infrastructure maintainer,
I want a step-by-step migration guide with concrete examples,
So that I can confidently migrate services following a proven pattern.

**Acceptance Criteria:**

**Given** the file `docs/migration-guide.md` exists
**When** I read the guide
**Then** I see:
- Step-by-step migration process
- Before/after code examples for each service type
- Common pitfalls and how to avoid them
- Troubleshooting section for common issues
**And** examples cover different service types (container, native, with/without database)

---

### Story 6.3: Create Service Template Usage Guide

As an infrastructure maintainer,
I want documentation explaining how to use the service template,
So that I can quickly create new services correctly.

**Acceptance Criteria:**

**Given** the file `docs/service-template-guide.md` exists
**When** I read the guide
**Then** I understand:
- How to copy and customize the template
- What each field means and when to use it
- Required vs optional fields
- Examples for common service configurations
**And** guide references the actual template file

---

### Story 6.4: Document Settings File Service Visibility

As an infrastructure maintainer,
I want clear documentation on viewing enabled services,
So that I can quickly understand the server's current configuration.

**Acceptance Criteria:**

**Given** the `hosts/Server/settings.nix` file structure
**When** I want to see all enabled services
**Then** the documentation explains:
- Where to look for service enablement
- How services are organized in settings
- How to query enabled services programmatically
**And** the settings file itself has inline comments explaining the structure

---

### Story 6.5: Ensure Single-File Service Comprehension

As an infrastructure maintainer,
I want to understand a complete service by reading one file,
So that I don't need to search multiple files to understand configuration.

**Acceptance Criteria:**

**Given** any service module file
**When** I read the file
**Then** I can see:
- Service contract (enable, port, persistence, backups, routing)
- Service implementation (systemd/container config)
- Secrets configuration (SOPS paths)
- All in one file with clear section headers
**And** no external file references are needed to understand the service

---

## Epic 7: Full Service Migration

**Epic Goal:** All 15+ services migrated to the new pattern, operating with consistent configuration, full backup coverage, and clean codebase ready for future additions.

### Story 7.1: Migrate Media Services - Jellyfin

As an infrastructure maintainer,
I want Jellyfin migrated to the new service contract,
So that my primary media server follows the standardized pattern.

**Acceptance Criteria:**

**Given** existing Jellyfin configuration in `modules/server/media/video/`
**When** I migrate to the new pattern
**Then**:
- Service contract defined with all required fields
- Persistence paths aggregated via collector
- Backup directories aggregated via collector
- Traefik routing generated automatically
- VM test created and passing
**And** migration follows commit convention
**And** zero downtime during cutover

---

### Story 7.2: Migrate Media Services - Jellyseerr

As an infrastructure maintainer,
I want Jellyseerr migrated to the new service contract,
So that media request management follows the standardized pattern.

**Acceptance Criteria:**

**Given** existing Jellyseerr configuration
**When** I migrate to the new pattern
**Then**:
- Service contract defined with all required fields
- Depends on Jellyfin (dependency validated)
- Persistence and backup aggregated
- VM test created and passing
**And** migration follows commit convention

---

### Story 7.3: Migrate Media Services - Immich

As an infrastructure maintainer,
I want Immich migrated to the new service contract,
So that photo management follows the standardized pattern with proper database integration.

**Acceptance Criteria:**

**Given** existing Immich configuration with PostgreSQL database
**When** I migrate to the new pattern
**Then**:
- Service contract defined including database declaration
- PostgreSQL auto-provisioned via collector
- Container configuration using database connection details
- SOPS secrets properly integrated
- VM test created and passing
**And** migration follows commit convention
**And** zero downtime for family photo access

---

### Story 7.4: Migrate *arr Stack - Sonarr, Radarr, Bazarr, Prowlarr

As an infrastructure maintainer,
I want all *arr services migrated to the new service contract,
So that the media automation stack follows consistent patterns.

**Acceptance Criteria:**

**Given** existing *arr configurations in `modules/server/arrs/`
**When** I migrate each service (Sonarr, Radarr, Bazarr, Prowlarr)
**Then** each service:
- Has contract defined with required fields
- Has persistence and backup aggregated
- Has Traefik routing with appropriate middleware
- Has VM test passing
**And** services can be migrated independently
**And** each migration follows commit convention

---

### Story 7.5: Migrate Download Clients - qBittorrent, Nicotine+

As an infrastructure maintainer,
I want download clients migrated to the new service contract,
So that download services follow the standardized pattern.

**Acceptance Criteria:**

**Given** existing download client configurations
**When** I migrate each service
**Then** each service:
- Has contract defined with required fields
- Has persistence for download data
- Has appropriate Traefik routing
- Has VM test passing
**And** each migration follows commit convention

---

### Story 7.6: Migrate Authentication - Authelia, LLDAP

As an infrastructure maintainer,
I want authentication services migrated to the new service contract,
So that SSO infrastructure follows the standardized pattern.

**Acceptance Criteria:**

**Given** existing Authelia and LLDAP configurations
**When** I migrate each service
**Then** each service:
- Has contract defined with database declarations
- Has PostgreSQL auto-provisioned
- Has SOPS secrets properly configured
- Has integration test for auth flow
**And** authentication continues working for all protected services
**And** zero downtime during migration

---

### Story 7.7: Migrate Vaultwarden

As an infrastructure maintainer,
I want Vaultwarden migrated to the new service contract,
So that password management follows the standardized pattern.

**Acceptance Criteria:**

**Given** existing Vaultwarden configuration
**When** I migrate to the new pattern
**Then**:
- Service contract defined with all required fields
- Database properly provisioned
- Backup directories include all critical data
- SOPS secrets for admin token
- VM test created and passing
**And** zero downtime (critical family service)

---

### Story 7.8: Migrate Traefik

As an infrastructure maintainer,
I want Traefik itself migrated to use collector-generated configuration,
So that the reverse proxy integrates with the new pattern.

**Acceptance Criteria:**

**Given** existing Traefik configuration
**When** I migrate to collector integration
**Then**:
- Traefik reads dynamic config from collector output
- All service routes generated automatically
- Middleware chains properly configured
- Certificate management unchanged
**And** all existing routes continue working

---

### Story 7.9: Migrate Miscellaneous Services - Portfolio, Obsidian, Syncthing, File Server

As an infrastructure maintainer,
I want all remaining services migrated to the new pattern,
So that the entire server uses consistent configuration.

**Acceptance Criteria:**

**Given** existing misc service configurations
**When** I migrate each service
**Then** each service:
- Has contract defined with required fields
- Has persistence and backup aggregated
- Has appropriate routing configured
- Has VM test if applicable
**And** each migration follows commit convention

---

### Story 7.10: Remove Legacy Pattern Code

As an infrastructure maintainer,
I want all legacy `qgroget.services` pattern code removed,
So that the codebase is clean and maintains only the new pattern.

**Acceptance Criteria:**

**Given** all services have been migrated to `qgroget.serviceModules`
**When** I complete the cleanup
**Then**:
- Old `qgroget.services` options removed
- Legacy persistence declarations in settings.nix removed
- Legacy backup configurations removed
- Old Traefik manual configurations removed
**And** `nix flake check` passes
**And** all services continue working after cleanup
