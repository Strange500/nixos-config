# QGroget NixOS Configuration - Source Tree Analysis

**Date:** 2026-01-06
**Document Type:** Annotated Directory Structure

## Root Directory

```
nixos/
├── flake.nix                 # 🔑 ENTRY POINT - Flake definition, all hosts
├── flake.lock                # Locked input versions (auto-generated)
├── settings.nix              # Global qgroget option definitions
├── home.nix                  # Home-manager user configuration
├── hardware-configuration.nix # Legacy (host-specific versions used)
├── README.md                 # Project introduction
├── show_secret.sh            # ⚠️ SENSITIVE - Secret display script
├── backupvm.xml              # VM backup configuration
│
├── hosts/                    # Per-host configurations
├── modules/                  # Reusable NixOS modules
├── secrets/                  # SOPS-encrypted secrets
├── tests/                    # NixOS integration tests
├── docs/                     # This documentation
├── home/                     # Home-manager dotfiles
└── _bmad/                    # BMAD methodology files
```

## hosts/ Directory

Host-specific configurations following pattern: `hosts/<hostname>/configuration.nix`

```
hosts/
├── global.nix                # Shared configuration for all hosts
├── global_package.nix        # Common package definitions
├── setting.nix               # Dynamic host settings loader
│
├── Clovis/                   # Primary desktop workstation
│   ├── configuration.nix     # Host entry point
│   ├── disk-config.nix       # Disko disk layout (BTRFS/LUKS)
│   ├── hardware-configuration.nix  # Hardware-specific settings
│   └── settings.nix          # Host-specific qgroget options
│
├── Septimius/                # Secondary desktop
│   ├── configuration.nix
│   ├── disk-config.nix
│   ├── hardware-configuration.nix
│   └── settings.nix
│
├── Clotaire/                 # Additional desktop
│   ├── configuration.nix
│   ├── disk-config.nix
│   ├── hardware-configuration.nix
│   └── settings.nix
│
├── Server/                   # 🔑 HOMELAB SERVER
│   ├── configuration.nix     # Server entry, ZFS, Podman setup
│   ├── disk-config.nix       # ZFS pool configuration
│   ├── hardware-configuration.nix
│   └── settings.nix          # Server domain, service toggles
│
├── Cube/                     # Gaming device (Jovian NixOS)
│   ├── configuration.nix
│   ├── disk-config.nix
│   ├── hardware-configuration.nix
│   └── settings.nix
│
├── pi/                       # Raspberry Pi (aarch64)
│   ├── configuration.nix
│   └── settings.nix
│
└── installer/                # Custom installer ISO
    └── configuration.nix
```

## modules/ Directory

Reusable NixOS modules organized by function.

```
modules/
├── apps/                     # Application configurations
│   ├── basics.nix            # Core CLI utilities
│   ├── browser/              # Firefox with extensions
│   │   └── ...
│   ├── cours.nix             # Educational software
│   ├── crypto.nix            # Cryptocurrency tools
│   ├── desktopsApps.nix      # GUI applications
│   ├── dev.nix               # Development tools
│   ├── kitty/                # Terminal emulator config
│   │   └── ...
│   ├── media.nix             # Media applications
│   ├── nvim.nix              # 🔑 Neovim (NVF) configuration
│   ├── oh-my-zsh/            # Shell configuration
│   │   └── ...
│   └── syncthing/            # File synchronization
│       └── ...
│
├── desktop/                  # Desktop environment modules
│   ├── hyprDesktop.nix       # 🔑 Desktop router (selects WM)
│   ├── niri.nix              # Niri window manager config
│   ├── hyprland/             # Hyprland configuration
│   │   ├── hyprland.nix
│   │   └── addons/
│   │       ├── hypridle/     # Idle management
│   │       ├── hyprlock/     # Lock screen
│   │       └── hyprpanel/    # Status bar
│   └── stylix/               # System-wide theming
│       └── ...
│
├── game/                     # Gaming configuration
│   ├── game.nix              # Steam, gaming packages
│   ├── script.nix            # Gaming scripts
│   └── steamImport.nix       # Steam library import
│
├── logo/                     # Branding assets
│   ├── default.nix           # Logo module
│   └── assets/               # Image files
│       └── ...
│
├── server/                   # 🔑 HOMELAB SERVICES
│   ├── default.nix           # Server module entry point
│   ├── options.nix           # qgroget.services option defs
│   ├── settings.nix          # Auto-persistence config
│   │
│   ├── SSO/                  # Authentication
│   │   └── default.nix       # Authelia + LLDAP
│   │
│   ├── arrs/                 # Media automation
│   │   └── default.nix       # Sonarr, Radarr, Bazarr, Prowlarr
│   │
│   ├── backup/               # Backup solutions
│   │   └── default.nix       # Restic + BorgBackup
│   │
│   ├── dashboard/            # Homepage dashboard
│   │   └── default.nix
│   │
│   ├── dns/                  # DNS services
│   │   └── default.nix
│   │
│   ├── downloaders/          # Download managers
│   │   └── default.nix       # qBittorrent (VPN), Nicotine+
│   │
│   ├── homeAssistant/        # Home automation (disabled)
│   │   └── ...
│   │
│   ├── media/                # Media services
│   │   ├── default.nix
│   │   ├── photo/
│   │   │   └── default.nix   # 🔑 Immich photo management
│   │   └── video/
│   │       ├── default.nix   # 🔑 Jellyfin media server
│   │       └── jellyseer.nix # Media requests
│   │
│   ├── misc/                 # Miscellaneous services
│   │   ├── default.nix
│   │   ├── fileServer.nix    # File sharing
│   │   ├── forgero.nix       # Forgejo git server
│   │   ├── obsidian.nix      # Notes publishing
│   │   ├── portfolio.nix     # Personal website
│   │   └── syncthing.nix     # File sync
│   │
│   ├── password-manager/     # Credentials
│   │   └── default.nix       # Vaultwarden
│   │
│   ├── security/             # Security tools (disabled)
│   │   └── ...               # CrowdSec
│   │
│   └── traefik/              # 🔑 Reverse proxy
│       └── default.nix       # Auto-routing, TLS, middlewares
│
├── shared/                   # Cross-host modules
│   ├── default.nix
│   └── syncthingSettings.nix # Syncthing folder definitions
│
└── system/                   # Core system modules
    ├── remoteAccess.nix      # Tailscale, Sunshine
    ├── audio/
    │   └── audio.nix         # PipeWire configuration
    ├── bluetooth/
    │   └── bluetooth.nix
    ├── boot/
    │   └── plymouth.nix      # Boot splash
    ├── login/
    │   └── login.nix         # Display manager
    ├── tpm/
    │   └── tpm.nix           # TPM configuration
    └── update/
        └── update.nix        # Auto-update settings
```

## secrets/ Directory

SOPS-encrypted secrets (DO NOT decrypt or commit plaintext).

```
secrets/
└── secrets.yaml              # ⚠️ Encrypted with age
    # Contains:
    # - server/jellyfin/user/*/password
    # - server/traefik/clientCaCert
    # - server/authelia/* (JWT, OIDC, SMTP)
    # - server/lldap/* (admin password, JWT)
    # - server/vaultwarden/*
    # - server/restic/repoPassword
    # - server/borg/repoPassword
    # - git/ssh/private
    # - server/immich/db_password
    # - server/arr-basic-auth
```

## tests/ Directory

NixOS VM-based integration tests.

```
tests/
├── jellyfin/                 # Jellyfin service test
│   └── default.nix           # VM test definition
└── jellyseerr/               # Jellyseerr service test
    └── default.nix
```

Run with: `nix build .#checks.x86_64-linux.jellyfinTest`

## home/ Directory

Home-manager dotfiles and assets.

```
home/
├── .config/                  # XDG config files
│   └── ...                   # (copied to ~/.config)
├── .local/                   # Local data
│   └── ...                   # (copied to ~/.local)
└── wallpapers/               # Theme-specific wallpapers
    ├── default/
    └── wide/
```

## Key Files Reference

| File | Purpose | Edit When |
|------|---------|-----------|
| `flake.nix` | Host definitions, inputs | Adding hosts, updating deps |
| `settings.nix` | Global options | Adding new qgroget options |
| `hosts/<host>/settings.nix` | Host config | Customizing specific host |
| `modules/server/options.nix` | Service options | Adding new service fields |
| `modules/server/traefik/default.nix` | Routing | Modifying proxy behavior |
| `modules/desktop/hyprDesktop.nix` | Desktop routing | Adding window managers |
| `secrets/secrets.yaml` | Secrets | Via SOPS only |

## Module Import Graph

```
flake.nix
└── hosts/<host>/configuration.nix
    └── hosts/global.nix
        ├── settings.nix (options)
        ├── hosts/global_package.nix
        ├── modules/system/* (audio, boot, login)
        ├── modules/game/game.nix
        ├── modules/shared/*
        └── modules/logo/*
    └── modules/server/* (Server host only)
        ├── modules/server/default.nix
        │   ├── options.nix
        │   ├── settings.nix
        │   ├── media/* (jellyfin, immich)
        │   ├── arrs/* (sonarr, radarr)
        │   ├── traefik/*
        │   └── ... (all server modules)
```

---

_Generated using BMAD Method `document-project` workflow_
