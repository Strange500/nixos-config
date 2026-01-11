# Story 2.4: Implement PostgreSQL Database Auto-Provisioning

**Status:** ready-for-dev

**Epic:** 2 - Configuration Aggregation & Integration  
**Story ID:** 2.4  
**Story Key:** 2-4-implement-postgresql-database-auto-provisioning

---

## Story

As an infrastructure maintainer,
I want PostgreSQL databases automatically provisioned based on service declarations,
so that I don't need to manually create databases for each service.

## Acceptance Criteria

1. **Given** a service declares `databases = [{ type = "postgresql"; name = "immich"; user = "immich"; }]`
   - **When** the collector module evaluates
   - **Then** PostgreSQL is configured to:
     - Create the database with the specified name
     - Create the user with appropriate permissions
     - Expose connection details back to the service module
   - **And** the service module can access `databaseConfig.host`, `databaseConfig.port`, etc.

2. **Given** multiple services declare PostgreSQL databases
   - **When** the system builds
   - **Then** all declared databases are provisioned

3. **Given** a service with `databases` declared but the service is disabled
   - **When** the system builds
   - **Then** no database is provisioned for that service
   - **And** disabled services do not consume database resources

4. **Given** invalid database configuration (e.g., missing required fields)
   - **When** `nix flake check` runs
   - **Then** evaluation fails with clear error message containing:
     - The invalid field name
     - The service name
     - An example of correct usage

5. **Given** the collector has computed database configurations
   - **When** a service module queries for its database connection info
   - **Then** it receives structured data with:
     - `host`: PostgreSQL server hostname (e.g., "localhost")
     - `port`: PostgreSQL server port (e.g., 5432)
     - `database`: Database name as declared
     - `user`: Username as declared
     - `password`: From SOPS secrets (service-specific)

---

## Tasks / Subtasks

### Task 1: Define Database Declaration Schema (AC: #1)
- [ ] 1.1 Update `modules/server/options.nix` with `databases` option
  - [ ] Define as `lib.types.listOf (lib.types.submodule {...})`
  - [ ] Support multiple databases per service
  - [ ] Type: `type = lib.types.enum ["postgresql" "redis" "mongodb"]`
  - [ ] Name: `name = lib.types.str` (required, validated for uniqueness later)
  - [ ] User: `user = lib.types.str` (required for PostgreSQL)
  - [ ] Additional fields: `port`, `extraConfig` (optional)
- [ ] 1.2 Make `databases` optional field with default `[]`
- [ ] 1.3 Document database declaration pattern in schema

### Task 2: Implement Database Provisioning Logic in Collector (AC: #1, #2)
- [ ] 2.1 In `modules/server/collector.nix`, aggregate all database declarations
  - [ ] Filter enabled services only
  - [ ] Extract all `databases` lists
  - [ ] Flatten into single list of database declarations
- [ ] 2.2 Configure PostgreSQL for each declared database
  - [ ] Create database via `services.postgresql.ensureDatabases`
  - [ ] Create user via `services.postgresql.ensureUsers`
  - [ ] Set appropriate permissions for user on database
- [ ] 2.3 Generate database connection configuration
  - [ ] Create structured config with `host`, `port`, `database`, `user`
  - [ ] Store in module-accessible location for each service
  - [ ] Use pattern: `config.qgroget.databases.postgresql.<serviceName> = { ... }`

### Task 3: Implement Service-Level Database Access (AC: #5)
- [ ] 3.1 Create helper function in collector for service to query its databases
  - [ ] Access: `config.qgroget.server.<service>.databaseConfig`
  - [ ] Returns list of database configs for the service
  - [ ] Type: `lib.types.listOf (lib.types.submodule { options = { host = ...; port = ...; database = ...; user = ...; }; })`
- [ ] 3.2 Document pattern for service module to access database info
  - [ ] Example: accessing first database
  - [ ] Example: filtering databases by type
  - [ ] Example: passing to container environment variables
- [ ] 3.3 Ensure pattern works for both container and native services

### Task 4: Implement Disabled Service Handling (AC: #3)
- [ ] 4.1 Ensure collector only processes databases from enabled services
  - [ ] Use `lib.filterAttrs (name: cfg: cfg.enable) config.qgroget.server`
  - [ ] Only include databases from filtered enabled services
- [ ] 4.2 Verify disabled services don't affect PostgreSQL provisioning
  - [ ] Test: Disable a service with databases → database not created
  - [ ] Test: Re-enable service → database created

### Task 5: Implement Validation & Error Messages (AC: #4)
- [ ] 5.1 Add validation for database configuration
  - [ ] Required field validation: `type`, `name`, `user`
  - [ ] Type validation: `type` must be one of allowed database types
  - [ ] Name validation: alphanumeric + underscore only (PostgreSQL naming rules)
- [ ] 5.2 Add assertion for missing required fields
  - [ ] Error message format:
    ```
    Service 'immich' declares database with missing required field 'user'
    
    All PostgreSQL databases require: type, name, user
    
    Example:
      databases = [{
        type = "postgresql";
        name = "immich";
        user = "immich";
      }];
    ```
- [ ] 5.3 Add assertion for invalid database names
  - [ ] Must start with letter/underscore
  - [ ] Only alphanumeric + underscore allowed
  - [ ] PostgreSQL maximum 63 characters
  - [ ] Error message with concrete example

### Task 6: PostgreSQL Integration (AC: #1, #2)
- [ ] 6.1 Configure `services.postgresql` in collector
  - [ ] Ensure PostgreSQL is enabled when databases declared
  - [ ] Set appropriate PostgreSQL version if not already set
  - [ ] Document version compatibility
- [ ] 6.2 Use PostgreSQL's built-in database/user provisioning
  - [ ] Use `ensureDatabases` for database creation
  - [ ] Use `ensureUsers` for user creation with ownership
  - [ ] Set proper permissions (GRANT for user on database)
- [ ] 6.3 Handle user permissions
  - [ ] User should have SELECT, INSERT, UPDATE, DELETE on own database
  - [ ] Use Nix's `ensureUsers` mechanism
  - [ ] Document permission model

### Task 7: Secrets Integration (AC: #5)
- [ ] 7.1 Document how services access database passwords
  - [ ] Passwords stored in SOPS at `server/<service>/db_password`
  - [ ] Service module loads password from SOPS
  - [ ] Password not in Nix store (pure secrets handling)
- [ ] 7.2 Provide pattern for services to use database password
  - [ ] Container example: environment variable injection from SOPS credential
  - [ ] Native service example: environment variable from SOPS secret
  - [ ] Document LoadCredential pattern with SOPS

### Task 8: Testing (Evaluation + Integration)
- [ ] 8.1 Update `tests/collector/eval-test.nix` with database provisioning tests
  - [ ] Test: Single service with one database → database config generated
  - [ ] Test: Multiple services with databases → all configs generated
  - [ ] Test: Disabled service with database → no config generated
  - [ ] Test: Invalid database config → assertion error with message
  - [ ] Test: Missing required field → assertion error
- [ ] 8.2 Verify `nix flake check` passes all database tests
- [ ] 8.3 Update existing service VM tests (Immich, Authelia) to verify database provisioning
  - [ ] Test: Database was created with correct name
  - [ ] Test: User can connect to database
  - [ ] Test: Connection details match what service received

### Task 9: Documentation (AC: #5)
- [ ] 9.1 Update `modules/server/_template/default.nix`
  - [ ] Add example `databases` declaration with full inline comments
  - [ ] Show both single and multiple database scenarios
  - [ ] Include password/secrets pattern example
- [ ] 9.2 Update architecture documentation
  - [ ] Document database provisioning flow (declaration → collector → PostgreSQL)
  - [ ] Show data flow diagram: service declaration → collector aggregation → PostgreSQL provisioning → connection details back to service
  - [ ] Document Permission model and security considerations
- [ ] 9.3 Create database integration guide (if not already in migration guide)
  - [ ] Step-by-step: How to add databases to a service
  - [ ] Examples for common database configurations
  - [ ] Troubleshooting section

### Task 10: Integration Testing (AC: #1, #2, #3)
- [ ] 10.1 Create comprehensive integration test for database provisioning
  - [ ] Use NixOS VM test framework
  - [ ] Start PostgreSQL service
  - [ ] Provision databases for multiple services
  - [ ] Verify databases exist with correct names/users
  - [ ] Verify permissions are correct
  - [ ] Test service can connect to its assigned database
- [ ] 10.2 Test database service dependency
  - [ ] Service declares `dependsOn = ["postgresql"]`
  - [ ] Verify PostgreSQL starts before services requiring databases
  - [ ] Verify startup order is respected

---

## Dev Notes

### Relevant Architecture Patterns & Constraints

**Service Contract Pattern (Pattern 2):**
Service contracts define the `databases` field at the top level. The database declaration is part of the service contract, not nested in a separate section. This keeps database configuration visible and accessible.

**Collector Aggregation Pattern (Pattern 5 - Three-Section Module Structure):**
The collector module is responsible for:
1. Aggregating database declarations from all enabled services
2. Configuring PostgreSQL with `ensureDatabases` and `ensureUsers`
3. Exposing connection details back to service modules

**Database Connection Information Pattern (Pattern 8):**
Service modules receive structured database configuration (not pre-formatted connection strings). They decide how to pass information to their application:
- Container services: environment variables from SOPS credentials
- Native services: environment variables or config files from SOPS

**PostgreSQL Integration (Architecture Decision 7):**
The design supports multiple database types but PostgreSQL is the primary focus. Other database types (Redis, MongoDB) can be added incrementally.

### Project Structure Notes

**Key Files to Touch:**
1. `modules/server/options.nix` - Add database schema to service contract
2. `modules/server/collector.nix` - Add database aggregation and PostgreSQL provisioning logic
3. `modules/server/_template/default.nix` - Add database declaration example
4. `tests/collector/eval-test.nix` - Add database aggregation tests
5. `tests/integration/` - Add database provisioning integration test
6. `docs/architecture.md` - Add database provisioning flow documentation

**PostgreSQL Configuration Location:**
NixOS standard PostgreSQL module: `services.postgresql`
- Database provisioning: `services.postgresql.ensureDatabases`
- User provisioning: `services.postgresql.ensureUsers`
- Existing configuration likely already present in `modules/server/` or via `modules/system/`

**Service Dependency Chain:**
- Services declaring databases implicitly depend on PostgreSQL
- The collector should:
  - Auto-enable PostgreSQL if any service declares databases
  - Not require explicit `dependsOn = ["postgresql"]` (though services can declare it for explicitness)
  - Handle case where PostgreSQL is already enabled elsewhere

**SOPS Secrets Pattern:**
Database passwords are stored in SOPS at:
```yaml
server/<service>/db_password: <encrypted_password>
```

Services access password via:
```nix
systemd.services.<service>.environment.DATABASE_PASSWORD = 
  "$(cat ${config.sops.secrets."server/<service>/db_password".path})";
```

### Alignment with Unified Project Structure

This story aligns with:
- **Pattern 4 (SOPS Secret Paths):** Database passwords use `server/<service>/db_password` pattern
- **Pattern 5 (Three-Section Module Structure):** Collector handles Section 2 (implementation) for database provisioning
- **Pattern 7 (Traefik Middleware Declaration):** Similar pattern for database configuration - predefined structure with validation
- **Pattern 8 (Database Connection Information):** Core pattern this story implements

### References

- **Architecture Decision 7:** Multiple database support with full connection details
- **Architecture Decision 8:** Database connection information as structured data
- **Service Contract Pattern (Section 5):** Database declaration as part of contract
- **Collector Aggregation Pattern (Section 3):** Collector responsible for database provisioning
- **Testing Strategy (Decision 10):** Per-service tests verify database provisioning
- Source: [architecture.md - Database Integration](docs/architecture.md#database-integration)
- Source: [epics.md - Story 2.4](docs/epics.md#story-24-implement-postgresql-database-auto-provisioning)

---

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5 (via GitHub Copilot)

### Completion Notes

**Story Generation Context:**
- Generated from complete epic analysis in `_bmad-output/planning-artifacts/epics.md`
- Architecture reviewed: `_bmad-output/planning-artifacts/architecture.md` (database integration sections)
- Sprint status: Story 2-4 in Epic 2 (Configuration Aggregation & Integration)
- Previous story context: Story 2-1 (Persistence Path Aggregation - DONE), Story 2-3 (Traefik Routing - IN REVIEW)

**Architectural Alignment:**
- Leverages existing NixOS PostgreSQL module (`services.postgresql`)
- Follows Pattern 8 (Database Connection Information - structured data)
- Implements Architecture Decision 7 (Multiple database support)
- Collector module as single source of truth for database provisioning
- Evaluation-time validation ensures build-time error detection

**Developer Guardrails:**
- Clear acceptance criteria aligned with acceptance tests
- 10 concrete tasks with specific subtasks
- Validation requirements prevent common mistakes (missing fields, invalid names)
- Secrets handling follows established SOPS pattern
- Testing strategy covers both eval-time and VM integration tests
- Documentation updates ensure onboarding clarity

**Common LLM Mistakes Prevented:**
1. **Database auto-generation:** Story explicitly requires explicit `name` and `user` fields (prevents silent failures from typos)
2. **Over-automation:** Collector only provisions for enabled services (prevents resource waste)
3. **Unclear error messages:** Task 5 specifies exact error format with examples (prevents developer confusion)
4. **Secrets in Nix store:** Task 7 emphasizes SOPS integration and LoadCredential pattern (prevents credential leaks)
5. **Incompatible abstractions:** Pattern 8 ensures service modules can use databases whether implemented as containers or native services (prevents implementation-specific coupling)

**Integration with Previous Stories:**
- **Story 2-1 (Persistence):** Database and persistence are independent aggregations; database provisioning can occur without persistent data declaration
- **Story 2-3 (Traefik):** No interaction; databases are internal infrastructure, not exposed via Traefik
- **Story 1.5 (Module Entry Point):** Collector must be imported in `modules/server/default.nix` (already exists)

### File List

**Files to Create:**
- `tests/integration/database-provisioning.nix` (New database provisioning integration test)

**Files to Modify:**
- `modules/server/options.nix` (Add `databases` option to service contract)
- `modules/server/collector.nix` (Add database aggregation and PostgreSQL provisioning)
- `modules/server/_template/default.nix` (Add database declaration example)
- `tests/collector/eval-test.nix` (Add database aggregation tests)
- `docs/architecture.md` (Add database provisioning flow section)

**Files Potentially Affected (Review Only):**
- `modules/server/media/photo/immich/default.nix` (Will demonstrate database usage pattern once this story complete)
- `modules/server/SSO/authelia/default.nix` (Will demonstrate database usage pattern once this story complete)
- `secrets/secrets.yaml` (Add database password entries for services that need them)

---

## Next Story Context

**Dependency:** Story 2-4 must be complete before Story 2-5 (Implement Dependency Validation) can fully validate service dependencies on PostgreSQL.

**Related Stories:**
- **Story 7-3 (Migrate Immich):** First concrete implementation using database provisioning from this story
- **Story 7-6 (Migrate Authelia):** Second implementation using database provisioning

---

