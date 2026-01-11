# QGroget NixOS Configuration - Architecture

**Date:** 2026-01-06
**Document Type:** Technical Architecture

## System Overview

This document describes the architecture of the QGroget NixOS configuration, a flake-based infrastructure managing multiple hosts with shared modules and centralized secrets.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           flake.nix                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ commonModules│  │desktopModules│  │serverModules│                 │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │
└─────────┼────────────────┼────────────────┼─────────────────────────┘
          │                │                │
          ▼                ▼                ▼
    ┌─────────────────────────────────────────────┐
    │              nixosConfigurations             │
    ├─────────┬─────────┬─────────┬───────────────┤
    │ Clovis  │Septimius│ Server  │   Cube/pi     │
    │(desktop)│(desktop)│(server) │  (special)    │
    └─────────┴─────────┴─────────┴───────────────┘
```

## Module Composition Strategy

### Common Modules (All Hosts)
Applied to every host via `commonModules`:

```nix
commonModules = [
  home-manager.nixosModules.default    # User environment
  stylix.nixosModules.stylix           # Theming
  disko.nixosModules.disko             # Declarative partitioning
  sops-nix.nixosModules.sops           # Secrets management
  chaotic.nixosModules.default         # Chaotic Nyx packages
  nur.modules.nixos.default            # Nix User Repository
  nvf-neovim                           # System-wide neovim
];
```

### Desktop Modules
Additional modules for desktop hosts:

```nix
desktopModules = [
  impermanence.nixosModules.impermanence  # Ephemeral root
];
```

### Server Modules
Additional modules for the homelab server:

```nix
serverModules = [
  impermanence.nixosModules.impermanence
  declarative-jellyfin.nixosModules.default  # Media server
  quadlet-nix.nixosModules.quadlet           # Container management
  portfolio.nixosModules.default             # Personal website
];
```

## Configuration Hierarchy

```
flake.nix
├── inputs (external dependencies)
├── commonModules, desktopModules, serverModules
└── nixosConfigurations
    └── <hostname>
        ├── hosts/<hostname>/configuration.nix
        │   ├── hosts/global.nix
        │   │   ├── settings.nix (global qgroget options)
        │   │   ├── hosts/global_package.nix
        │   │   ├── modules/system/* (audio, boot, bluetooth)
        │   │   ├── modules/game/game.nix
        │   │   ├── modules/shared/*
        │   │   └── modules/logo/*
        │   ├── hosts/<hostname>/settings.nix (host-specific)
        │   ├── hosts/<hostname>/hardware-configuration.nix
        │   └── hosts/<hostname>/disk-config.nix
        └── [module-specific configurations]
```

## Options System

### Global Options (`settings.nix`)

The `qgroget` option namespace provides centralized configuration:

```nix
qgroget = {
  secretAgeKeyPath = "/var/lib/sops/age/keys.txt";
  user.username = "strange";
  nixos = {
    isDesktop = true;
    auto-update = false;
    theme = "wide";
    desktop = {
      desktopEnvironment = "niri";  # or "hyprland", "kde", "gnome"
      loginManager = "dms";          # or "gdm", "ly"
      monitors = [", preferred, auto, 1"];
    };
    remote-access = {
      enable = true;
      tailscale.enable = true;
      sunshine.enable = false;
    };
    apps = {
      basic = true;
      school = false;
      dev.enable = true;
      media = true;
      crypto = false;
    };
    gaming = true;
    vr = false;
  };
};
```

### Server Options (`modules/server/options.nix`)

Server-specific options for service management:

```nix
qgroget.services.<name> = {
  name = "service-subdomain";
  url = "http://127.0.0.1:PORT";
  type = "private" | "public";
  persistedData = ["/var/lib/service"];
  backupDirectories = ["/var/lib/service/data"];
  middlewares = ["SSO"];
  traefikDynamicConfig = { };
  journalctl = true;
  unitName = "service.service";
};

qgroget.backups.<name> = {
  paths = ["/backup/path"];
  systemdUnits = ["service.service"];
  priority = 10;
  preBackup = "script";
  postBackup = "script";
};
```

## Server Architecture

### Service Registration Flow

```
Service Module (e.g., jellyfin)
        │
        ▼
qgroget.services.jellyfin = { ... }
        │
        ├──► Traefik (modules/server/traefik/default.nix)
        │    - Auto-generates router/service config
        │    - Applies TLS (Let's Encrypt)
        │    - Applies middlewares (SSO, rate-limit)
        │
        ├──► Impermanence (modules/server/settings.nix)
        │    - Declares persistent directories
        │
        └──► Backup (modules/server/backup/default.nix)
             - Includes in restic backup jobs
```

### Network Architecture

```
Internet
    │
    ▼
Traefik (ports 80, 443)
    │
    ├── *.qgroget.com (public services)
    │   └── mTLS: disabled
    │   └── Middlewares: service-specific
    │
    └── *.qgroget.com (private services)
        └── mTLS: enabled (client cert required)
        └── Middlewares: SSO + service-specific
```

### Container Architecture

The server uses **Podman with Quadlet** for containers:

```nix
virtualisation.quadlet = {
  enable = true;
  autoEscape = true;
  autoUpdate.enable = true;
};

# Container example (vaultwarden)
virtualisation.quadlet.containers.vaultwarden = {
  containerConfig = {
    image = "docker.io/vaultwarden/server:latest";
    volumes = ["${containerDir}/vaultwarden:/data:Z"];
    publishPorts = ["4743:80"];
  };
};
```

### Service Categories

```
modules/server/
├── SSO/              # Authelia + LLDAP
├── arrs/             # Sonarr, Radarr, Bazarr, Prowlarr
├── backup/           # Restic + BorgBackup
├── dashboard/        # Homepage/dashboard
├── dns/              # DNS services
├── downloaders/      # qBittorrent, Nicotine+
├── media/
│   ├── photo/        # Immich
│   └── video/        # Jellyfin, Jellyseerr
├── misc/             # Obsidian, Portfolio, Syncthing
├── password-manager/ # Vaultwarden
├── security/         # CrowdSec (disabled)
└── traefik/          # Reverse proxy
```

## Desktop Architecture

### Window Manager Configuration

```
modules/desktop/hyprDesktop.nix (router)
        │
        ├── hyprland/ (if desktopEnvironment == "hyprland")
        │   ├── hyprland.nix
        │   └── addons/ (hypridle, hyprlock, hyprpanel)
        │
        └── niri.nix (if desktopEnvironment == "niri")
```

### Application Modules

```
modules/apps/
├── basics.nix        # Core utilities
├── browser/          # Firefox configuration
├── cours.nix         # School applications
├── crypto.nix        # Cryptocurrency tools
├── desktopsApps.nix  # Desktop-specific apps
├── dev.nix           # Development tools
├── kitty/            # Terminal emulator
├── media.nix         # Media applications
├── nvim.nix          # Neovim configuration (NVF)
├── oh-my-zsh/        # Shell configuration
└── syncthing/        # File sync
```

## Security Architecture

### Secrets Management

```
secrets/secrets.yaml (SOPS encrypted)
        │
        ▼
sops-nix module (decrypts at runtime)
        │
        ├── System secrets → /run/secrets/*
        │   (ownership: service-specific users)
        │
        └── User secrets → /run/user/1000/secrets/*
            (home-manager managed)
```

**Key patterns:**
- Age key stored at `/var/lib/sops/age/keys.txt`
- Secrets never in Nix store (runtime decryption)
- Service-specific ownership via `owner`/`group`

### Impermanence

Desktop hosts use BTRFS with ephemeral root:

```nix
environment.persistence."/persist" = {
  enable = true;
  hideMounts = true;
  directories = [
    "/var/lib/nixos"
    "/var/lib/systemd"
    "/etc/NetworkManager"
    "/etc/ssh"
  ];
  files = [
    "/etc/machine-id"
  ];
};
```

Server persists to ZFS:
```nix
environment.persistence."/persist".directories = [
  # Auto-populated from qgroget.services.*.persistedData
  "/var/lib/containers"
  "/var/lib/postgresql"
];
```

### Authentication Flow

```
User Request
     │
     ▼
Traefik (checks route)
     │
     ├── Public service → Direct pass-through
     │
     └── Private service
         │
         ├── mTLS check (client certificate)
         │
         └── Forward to Authelia
             │
             ├── Valid session → Forward to backend
             │
             └── No session → Redirect to login
                 │
                 ├── Username/Password (LLDAP backend)
                 │
                 └── 2FA (TOTP)
```

## Storage Architecture

### Server (ZFS)

```
zpool: rpool
├── /           (root)
├── /nix        (Nix store)
├── /persist    (persistent state)
└── /var/log    (logs)

zpool: datapool (separate drives)
└── /mnt/data
    ├── immich/   (photos)
    └── media/    (movies, tv)
```

### Desktop (BTRFS)

```
LUKS encrypted volume
└── BTRFS
    ├── @ (root, ephemeral)
    ├── @persist (persistent state)
    ├── @nix (Nix store)
    └── @home (user data)
```

## Deployment Model

### Build Process

```bash
# 1. Evaluate configuration
nix flake check

# 2. Build system derivation
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# 3. Activate (local)
sudo nixos-rebuild switch --flake .#<host>

# 4. Or remote deployment
nixos-rebuild switch --flake .#<host> --target-host user@host --use-remote-sudo
```

### CI/CD (Testing)

```nix
checks.${system} = {
  jellyfinTest = import ./tests/jellyfin { inherit pkgs; };
  jellyseerrTest = import ./tests/jellyseerr { inherit pkgs; };
};
```

Run with: `nix build .#checks.x86_64-linux.jellyfinTest`

## External Dependencies

### Flake Inputs

| Input | Purpose | Source |
|-------|---------|--------|
| nixpkgs | Base packages | github:nixos/nixpkgs/nixos-unstable |
| home-manager | User environment | github:nix-community/home-manager |
| stylix | System theming | github:danth/stylix |
| hyprland | Window manager | github:hyprwm/Hyprland |
| sops-nix | Secrets | github:Mic92/sops-nix |
| disko | Disk partitioning | github:nix-community/disko |
| impermanence | Ephemeral root | github:nix-community/impermanence |
| quadlet-nix | Container management | github:SEIAROTg/quadlet-nix |
| declarative-jellyfin | Media server | github:Sveske-Juice/declarative-jellyfin |
| nvf | Neovim framework | github:NotAShelf/nvf |
| jovian-nixos | Gaming/Steam Deck | github:Jovian-Experiments/Jovian-NixOS |

---

_Generated using BMAD Method `document-project` workflow_
