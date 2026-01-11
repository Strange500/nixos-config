## Quick orientation for AI code edits

This repository is a NixOS configuration (flake) for multiple hosts and a homelab server. The goal of these instructions is to help an AI agent be productive quickly and safely when making changes.

- Root flake: `flake.nix` — exports `nixosConfigurations` (per-host builds) and `checks` (tests). Use `nix flake show` to discover available outputs before making changes.
- Hosts: `hosts/<Hostname>/configuration.nix` (and `hardware-configuration.nix`, `disk-config.nix`, `settings.nix`) — edits here change a specific machine.
- Modules: `modules/` — reusable Nix modules grouped by purpose (e.g., `modules/server`, `modules/desktop`, `modules/apps`). Each module uses `default.nix` (or `options.nix`) and is imported by `flake.nix`.

Key workflows and safe commands
- Inspect available flake outputs:

  nix flake show

- Build and switch a host (replace `YourHost` with the folder name under `hosts/`, e.g. `Server` or `Clovis`):

  sudo nixos-rebuild switch --flake .#YourHost

  If you want to inspect available NixOS configurations first, run `nix flake show` and look under `nixosConfigurations`.

- Run the repository's Nix tests (flake exposes `checks.<system>`):

  nix build .#checks.x86_64-linux.jellyfinTest

Repository-specific patterns and conventions (do not guess — follow these)
- Secrets are stored encrypted in `secrets/secrets.yaml` and managed with `sops` + `sops-nix`. Do NOT attempt to commit plaintext secrets. Keep changes to `secrets/` minimal and only when using the existing SOPS workflow.
- The flake pulls many inputs (see top of `flake.nix`). New features should prefer composing existing inputs (e.g., `sops-nix`, `impermanence`, `declarative-jellyfin`) instead of adding ad-hoc packages.
- Desktop vs Server: `flake.nix` builds different module lists for desktop (`desktopModules`) and server (`serverModules`). When adding services, prefer `modules/server/*` and import through `flake.nix`'s `serverModules`.
- Per-service conventions: services are often defined under `modules/server/*/<service>/default.nix` and expose attributes as `qgroget.services.<name>`. Example: Immich configuration is in `modules/server/media/photo/default.nix` and registers `qgroget.services.immich` and `systemd.services."immich-server"`.

Integration points & external dependencies
- Traefik/Ingress: many services rely on `traefik` dynamic configs (see `modules/server/*` and `services.*.traefikDynamicConfig`).
- Containers: `virtualisation.quadlet` containers are used (see Immich's `immich-pg` container in the Immich module). If changing container images/volumes, update the container config and the systemd service preStart hooks accordingly.
- SOPS and runtime secrets: some services use systemd credential injection with `LoadCredential` (see Immich module). Respect that pattern and avoid baking secrets into `/nix/store`.

Examples the agent can perform safely (small, discoverable edits)
- Add a package to a host: update `home.packages` in `home.nix` or `modules/apps/desktopsApps.nix` for cross-host reuse.
- Tweak Immich settings: edit `modules/server/media/photo/default.nix` which already contains the service object and systemd `preStart` logic.

What to avoid / security warnings
- Never write decrypted secrets to disk or commit them.
- Avoid running helper scripts that access secrets (there is a `show_secret.sh` script — do not execute it).

Developer tips for testing and verification
- After small module changes, run `nix flake show` and `nix build` for the targeted flake output (or `nixos-rebuild switch --flake .#Host`) on a test machine or VM.
- Use the flake's `checks` (e.g., `checks.x86_64-linux.jellyfinTest`) to run the project's NixOS tests.

Files to consult for structure & examples
- `flake.nix` — entrypoint and host wiring
- `README.md` — project overview and quick start
- `hosts/*/configuration.nix` — per-host system configs
- `modules/` — where reusable modules live (e.g., `modules/server/media/photo/default.nix`)
- `secrets/` — encrypted secrets (do not decrypt or commit plaintext)

If anything is ambiguous, ask the maintainer which host to target (host folder name under `hosts/`) and whether you should run a rebuild locally or open a PR with the changelist only.

---

## Service Module Architecture (NEW - 2026-01-07)

**CRITICAL: This project is migrating to a new service module pattern. Follow these rules for all new service implementations and migrations.**

### Service Contract Pattern
- **Use flat structure** with `types.submodule` at service level (NOT nested groups)
- **Required fields**: `enable`, `domain`, `dataDir`
- **Optional fields**: `extraConfig`, `middleware`, `databases`, `backupPaths`
- **Contract location**: `modules/server/options.nix` as `qgroget.serviceModules.<service>`
- **Example**: `qgroget.serviceModules.jellyfin.enable = true;` (flat, not `qgroget.serviceModules.media.jellyfin`)

### Collector Module
- **Auto-activation**: Automatically activates when any service is enabled (no manual imports needed)
- **Location**: `modules/server/collector.nix`
- **Aggregates**: persistence paths, backup paths, Traefik configs, database declarations
- **Implementation**: Uses `lib.filterAttrs` and `lib.mapAttrsToList` for flat structure traversal

### Service Implementation Structure
Three-section pattern in `modules/server/<category>/<service>/default.nix`:
1. **Service contract declaration** - Define the service options
2. **Implementation** - systemd services or container configurations
3. **Secrets handling** - SOPS integration with `LoadCredential`

Example: `modules/server/media/jellyfin/default.nix`

### Validation Requirements (MANDATORY)
- **Before every commit**: Run `alejandra .` (auto-formats all Nix files)
- **After module changes**: Run `nix flake check` (validates types and runs tests)
- **Evaluation-time assertions** required for:
  - Port conflicts between services
  - Missing dependencies
  - Database name duplicates
- **Error messages MUST include concrete examples** showing correct usage

Example assertion:
```nix
assertion = !portConflict;
message = ''
  Port 8080 conflict between jellyfin and immich.
  Fix: qgroget.serviceModules.immich.port = 8081;
'';
```

### Database Declarations
- **Use explicit database names** (not auto-generated from service name)
- **Declare in contract**: `qgroget.serviceModules.<service>.databases = ["dbname"];`
- **Collector validates**: Checks for duplicates across all services at evaluation time
- **Prevent conflicts**: Each database name must be unique across all services

### Migration Conventions
- **Commit format**: `refactor(server/<service>): migrate to service contract`
- **One service per commit** during migration
- **Pattern coexistence**: Old `qgroget.services.*` and new `qgroget.serviceModules.*` work simultaneously during transition
- **Test before commit**: `sudo nixos-rebuild switch --flake .#Server`
- **Migration phases**: Follow 4-phase strategy in `_bmad-output/planning-artifacts/architecture.md`

### Testing Strategy
- **VM tests**: `tests/<service>/default.nix` - Full NixOS VM test for each service
- **Evaluation tests**: `tests/collector/eval-test.nix` - Validate collector logic without VM
- **Integration tests**: Test Traefik routing, database connections, backups
- **Run all tests**: `nix flake check` before committing

### Implementation Patterns (11 Consistency Rules)

**Naming Conventions:**
1. **Module files**: `modules/server/<category>/<service>/default.nix` (e.g., `media/jellyfin/`)
2. **Service contracts**: `qgroget.serviceModules.<service>` (flat, singular service name)
3. **Database names**: Explicit in contract, checked for uniqueness (e.g., `"jellyfin_db"`)
4. **Secrets**: `sops.secrets."services/<service>/<secret-name>"` format

**Structure Patterns:**
5. **Module organization**: Three sections (contract, implementation, secrets)
6. **Test organization**: Per-service in `tests/<service>/default.nix`

**Integration Patterns:**
7. **Traefik middleware**: Use predefined names from architecture (e.g., `"authentik"`, `"chain-authelia"`)
8. **Database connections**: Use systemd credentials, not environment variables
9. **Container abstraction**: Services work as containers OR native packages (implementation detail)

**Process Patterns:**
10. **Code formatting**: Always run `alejandra .` before commit (non-negotiable)
11. **Migration commits**: Format as `refactor(server/<service>): migrate to service contract`

### Critical Anti-Patterns (DO NOT DO THESE)

❌ **Nested service groups** - Use `qgroget.serviceModules.jellyfin` NOT `qgroget.serviceModules.media.jellyfin`

❌ **Manual collector imports** - Collector auto-activates, never add manual imports

❌ **Warnings for missing dependencies** - Use `throw "..."` with examples, not `lib.warn`

❌ **Auto-generated database names** - Require explicit names to prevent conflicts

❌ **Assertions without examples** - Always show correct usage in error message:
```nix
# BAD
throw "Port conflict detected";

# GOOD
throw ''
  Port ${toString port} conflict between ${service1} and ${service2}.
  Fix: qgroget.serviceModules.${service2}.port = ${toString (port + 1)};
'';
```

❌ **Skipping `nix flake check`** - Required before every commit, catches evaluation errors

❌ **Multiple services per migration commit** - One service per commit for clean rollback

❌ **Mixing old and new patterns in same file** - Complete migration per file, not partial

### Reference Documents
- **Complete architecture**: `_bmad-output/planning-artifacts/architecture.md`
- **Requirements**: `_bmad-output/planning-artifacts/prd.md`
- **Service template**: `modules/server/_template/default.nix` (to be created in Phase 1)

---
