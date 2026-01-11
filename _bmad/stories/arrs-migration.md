---
storyType: 'technical-migration'
category: 'service-refactor'
priority: 'medium'
status: 'in-progress'
created: '2025-01-10'
tags: ['service-contract', 'arrs', 'migration', 'phase-2']
---

# Story: Migrate *arr Services to Service Contract Pattern

## Overview

Migrate the *arr services module (`modules/server/arrs/default.nix`) from the legacy `qgroget.services.*` pattern to the new service contract architecture defined in `modules/server/options.nix`.

## Context

The *arr services module currently manages multiple services:
- `sonarr` - TV shows (general)
- `sonarr-anime` - TV shows (anime)
- `radarr` - Movies (general)
- `radarr-anime` - Movies (anime)
- `bazarr` - Subtitles
- `prowlarr` - Indexer management
- `autobrr` - Torrent automation
- `qui` - Autobrr UI
- `flaresolverr` - Cloudflare solver

These services use Quadlet containers and share authentication via Traefik basic auth middleware.

## Acceptance Criteria

### Service Contract Implementation

- [ ] Define `qgroget.serviceModules.sonarr` with required fields
- [ ] Define `qgroget.serviceModules.sonarr-anime` with required fields
- [ ] Define `qgroget.serviceModules.radarr` with required fields
- [ ] Define `qgroget.serviceModules.radarr-anime` with required fields
- [ ] Define `qgroget.serviceModules.bazarr` with required fields
- [ ] Define `qgroget.serviceModules.prowlarr` with required fields
- [ ] Define `qgroget.serviceModules.autobrr` with required fields
- [ ] Define `qgroget.serviceModules.qui` with required fields
- [ ] Define `qgroget.serviceModules.flaresolverr` with required fields

### Required Fields

Each service must declare:
- `enable` - Boolean activation
- `domain` - Domain name for routing
- `dataDir` - Data directory path

### Optional Fields

- `port` - Service port (with validation)
- `databases` - Database declarations (if needed)
- `backupPaths` - Backup directories
- `middleware` - Traefik middleware names

### Implementation Requirements

- [ ] Three-section module structure (contract, implementation, secrets)
- [ ] Maintain existing Quadlet container configurations
- [ ] Preserve shared basic auth middleware pattern
- [ ] Maintain pod-based architecture for service communication
- [ ] Keep existing user/group configurations (arr:media)

### Validation Requirements

- [ ] Port conflict detection between all *arr services
- [ ] Assertions with concrete error examples
- [ ] Database name uniqueness validation (if databases used)
- [ ] Required dependency checks (e.g., Prowlarr depends on Flaresolverr)

### Testing Requirements

- [ ] All services build successfully: `sudo nixos-rebuild switch --flake .#Server`
- [ ] Code formatting passes: `alejandra .`
- [ ] Flake check passes: `nix flake check`
- [ ] Services accessible via Traefik routes
- [ ] Basic auth middleware functions correctly
- [ ] Pod communication verified (services can reach each other)

## Technical Details

### Current Structure

```nix
qgroget.services = {
  sonarr-anime = {
    name = "sonarr-anime";
    url = "http://[::1]:8989";
    type = "private";
    middlewares = ["inject-basic-arr"];
    # ...
  };
  # ... other services
};
```

### Target Structure

```nix
qgroget.serviceModules = {
  sonarr-anime = {
    enable = true;
    domain = "sonarr-anime";
    dataDir = "/mnt/data/arr/sonarr-anime";
    port = 8989;
    middleware = ["inject-basic-arr"];
    backupPaths = ["/mnt/data/arr/sonarr-anime"];
  };
  # ... other services
};
```

### Special Considerations

1. **Shared Authentication**: All *arr services use the same basic auth middleware (`inject-basic-arr`) which is dynamically generated with secrets
2. **Pod Networking**: Services run in a Quadlet pod and communicate via pod-local networking
3. **Container Images**: Using LinuxServer.io images for most services
4. **Media Group**: All services share the `media` group for file access

### Files to Modify

- `modules/server/arrs/default.nix` - Main implementation
- `hosts/Server/configuration.nix` - Update service activation to use new pattern (future)
- Tests to add: `tests/arrs/default.nix` - VM test for *arr services

### Migration Strategy

1. **Phase 1**: Add service contracts alongside existing implementation
2. **Phase 2**: Migrate systemd/container configs to use contract values
3. **Phase 3**: Test all services in VM
4. **Phase 4**: Deploy to Server host

## Dependencies

- Service contract pattern defined in `modules/server/options.nix`
- Collector module in `modules/server/collector.nix`
- Service template in `modules/server/_template/default.nix`

## References

- Architecture: `.github/copilot-instructions.md` (Service Module Architecture section)
- Template: `modules/server/_template/default.nix`
- Example: `modules/server/media/jellyfin/default.nix`
- Current implementation: `modules/server/arrs/default.nix`

## Success Metrics

- All 9 *arr services migrated to contract pattern
- No service functionality regression
- Cleaner separation between service configuration and implementation
- Automatic collector integration (persistence, backups, Traefik)
- Improved error messages for misconfigurations

## Notes

- This is a complex migration due to the number of interdependent services
- Consider migrating services incrementally (one per commit) for easier rollback
- The basic auth middleware generation pattern is unique and must be preserved
- Pod architecture enables efficient inter-service communication without exposing all ports

## Rollback Plan

If issues arise:
1. Git revert the migration commit
2. Rebuild with `sudo nixos-rebuild switch --flake .#Server --rollback`
3. Verify services are accessible
4. Review logs: `journalctl -u <service-name>`
