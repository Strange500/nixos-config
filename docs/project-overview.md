# QGroget NixOS Configuration - Project Overview

**Date:** 2026-01-06
**Type:** NixOS Flake Configuration
**Architecture:** Modular Infrastructure as Code

## Executive Summary

QGroget is a comprehensive NixOS flake configuration managing a personal computing ecosystem including multiple desktop workstations, a self-hosted homelab server, gaming devices, and a Raspberry Pi. The project emphasizes reproducibility, declarative configuration, and security through encrypted secrets management.

The configuration powers **qgroget.com**, a homelab infrastructure providing media management, personal cloud services, authentication, and various self-hosted applications.

## Project Classification

- **Repository Type:** Monolith (single flake managing multiple hosts)
- **Project Type:** Infrastructure/NixOS Configuration
- **Primary Language:** Nix
- **Architecture Pattern:** Modular NixOS Module System

## Target Hosts

### Desktop Systems

| Host | Purpose | Key Features |
|------|---------|--------------|
| **Clovis** | Primary Workstation | Development, VR, gaming, full app suite |
| **Septimius** | Secondary Desktop | General use with impermanence |
| **Clotaire** | Additional Desktop | Standard desktop configuration |

### Server & Specialized

| Host | Purpose | Key Features |
|------|---------|--------------|
| **Server** | Homelab | ZFS, Podman/Quadlet, Traefik, all services |
| **Cube** | Gaming Device | Jovian NixOS (Steam Deck-like) |
| **pi** | Raspberry Pi | ARM64 (aarch64-linux) |
| **installer** | ISO Builder | Custom NixOS installer generation |

## Technology Stack Summary

| Category | Technology | Purpose |
|----------|------------|---------|
| **Operating System** | NixOS (unstable) | Base operating system |
| **Package Manager** | Nix Flakes | Declarative dependency management |
| **Window Manager** | Hyprland / Niri | Desktop environments |
| **Secrets** | SOPS + age | Encrypted secrets management |
| **Containers** | Podman + Quadlet | Container runtime |
| **Reverse Proxy** | Traefik | HTTPS routing and certificates |
| **Authentication** | Authelia + LLDAP | Single sign-on |
| **Media** | Jellyfin, Immich | Media and photo management |
| **Storage** | ZFS (Server), BTRFS (Desktop) | File systems |
| **Persistence** | Impermanence | Ephemeral root with explicit state |
| **Editor** | NVF (Neovim) | System-wide neovim configuration |

## Key Features

### Reproducibility
- Every system build is identical via Nix flakes
- Version-controlled configuration
- Declarative service definitions

### Security
- SOPS-encrypted secrets (age keys)
- mTLS for private services via Traefik
- Authelia SSO with 2FA support
- Ephemeral root filesystem (impermanence)

### Homelab Services
- **Media:** Jellyfin, Jellyseerr, Immich, Navidrome
- **Automation:** Sonarr, Radarr, Bazarr, Prowlarr
- **Downloads:** qBittorrent (VPN), Nicotine+
- **Security:** Vaultwarden, CrowdSec, Authelia
- **Utilities:** Syncthing, Portfolio site, Obsidian publish

### Desktop Experience
- Wayland-native (Hyprland/Niri)
- Stylix theming across all applications
- Development tools (JetBrains, VirtualBox, containers)
- Gaming support (Steam, VR)

## Architecture Highlights

### Module Organization
```
modules/
├── apps/          # Application configurations (browser, kitty, nvim)
├── desktop/       # Desktop environment configs (hyprland, niri, stylix)
├── game/          # Gaming-specific configuration
├── logo/          # Branding assets for services
├── server/        # All homelab service modules
├── shared/        # Cross-host shared configuration
└── system/        # Core system modules (audio, boot, TPM)
```

### Service Registration Pattern
Services declare themselves via `qgroget.services`:
```nix
qgroget.services.jellyfin = {
  name = "jellyfin";
  url = "http://127.0.0.1:8096";
  type = "public";
  middlewares = [];
  persistedData = ["/var/lib/jellyfin"];
};
```

This automatically:
- Creates Traefik routing rules
- Configures impermanence persistence
- Sets up backup inclusion

### Host Composition
```nix
# In flake.nix
mkSystem = hostname: extraModules:
  nixpkgs.lib.nixosSystem {
    modules = [
      ./hosts/${hostname}/configuration.nix
    ] ++ commonModules ++ extraModules;
  };

# Desktop hosts get: commonModules + desktopModules
# Server gets: commonModules + serverModules
```

## Development Overview

### Prerequisites

- NixOS or Nix package manager with flakes
- Age key for SOPS secrets decryption
- Git for version control

### Getting Started

1. Clone repository to `~/nixos`
2. Ensure age key exists at `/var/lib/sops/age/keys.txt`
3. Run `nix flake show` to see available configurations
4. Build with `sudo nixos-rebuild switch --flake .#<hostname>`

### Key Commands

| Action | Command |
|--------|---------|
| Show outputs | `nix flake show` |
| Build host | `sudo nixos-rebuild switch --flake .#Clovis` |
| Test build | `nix build .#nixosConfigurations.Server.config.system.build.toplevel` |
| Run tests | `nix build .#checks.x86_64-linux.jellyfinTest` |
| Update inputs | `nix flake update` |

## Repository Structure

```
nixos/
├── flake.nix              # Entry point - defines all hosts
├── flake.lock             # Locked input versions
├── settings.nix           # Global qgroget options
├── home.nix               # Home-manager configuration
├── hosts/                 # Per-host configurations
│   ├── global.nix         # Shared host settings
│   ├── <hostname>/        # Host-specific configs
├── modules/               # Reusable NixOS modules
├── secrets/               # SOPS-encrypted secrets
├── tests/                 # NixOS integration tests
└── docs/                  # This documentation
```

## Documentation Map

For detailed information, see:

- [index.md](./index.md) - Master documentation index
- [architecture.md](./architecture.md) - Detailed architecture
- [source-tree-analysis.md](./source-tree-analysis.md) - Directory structure
- [component-inventory.md](./component-inventory.md) - Module catalog
- [server-services.md](./server-services.md) - Homelab services
- [development-guide.md](./development-guide.md) - Development workflow

---

_Generated using BMAD Method `document-project` workflow_
