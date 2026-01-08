---
stepsCompleted:
  - step-01-init
  - step-02-discovery
inputDocuments:
  - _bmad-output/planning-artifacts/brainstorming-session-2026-01-06.md
  - docs/index.md
  - docs/project-overview.md
  - docs/architecture.md
workflowType: 'prd'
lastStep: 2
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

