# QGroget NixOS Configuration - Component Inventory

**Date:** 2026-01-06
**Document Type:** Module and Service Catalog

## Overview

This document catalogs all NixOS modules, services, and components in the QGroget configuration.

---

## Host Configurations

### Desktop Hosts

| Host | WM | Key Features | Settings Location |
|------|-----|--------------|-------------------|
| **Clovis** | Niri | VR, gaming, dev tools, JetBrains | `hosts/Clovis/settings.nix` |
| **Septimius** | Niri | Standard desktop | `hosts/Septimius/settings.nix` |
| **Clotaire** | Niri | Standard desktop | `hosts/Clotaire/settings.nix` |

### Server & Special Hosts

| Host | Purpose | Key Features |
|------|---------|--------------|
| **Server** | Homelab | ZFS, Podman, all services, qgroget.com |
| **Cube** | Gaming | Jovian NixOS, Steam Deck experience |
| **pi** | ARM device | Raspberry Pi (aarch64) |
| **installer** | ISO | Custom NixOS installer |

---

## Desktop Modules

### Window Managers (`modules/desktop/`)

| Module | File | Description |
|--------|------|-------------|
| **Desktop Router** | `hyprDesktop.nix` | Selects WM based on `desktopEnvironment` option |
| **Hyprland** | `hyprland/hyprland.nix` | Wayland compositor configuration |
| **Niri** | `niri.nix` | Scrolling tiling Wayland compositor |
| **Stylix** | `stylix/` | System-wide theming engine |

### Hyprland Addons

| Addon | Path | Purpose |
|-------|------|---------|
| Hypridle | `hyprland/addons/hypridle/` | Idle detection and actions |
| Hyprlock | `hyprland/addons/hyprlock/` | Lock screen |
| Hyprpanel | `hyprland/addons/hyprpanel/` | Status bar |

---

## Application Modules (`modules/apps/`)

| Module | File | Condition | Contents |
|--------|------|-----------|----------|
| **Basics** | `basics.nix` | `apps.basic` | Core utilities, CLI tools |
| **Browser** | `browser/` | Desktop | Firefox with extensions |
| **Kitty** | `kitty/` | Desktop | Terminal emulator |
| **Oh-My-Zsh** | `oh-my-zsh/` | All | Shell with plugins |
| **Neovim** | `nvim.nix` | All | NVF neovim configuration |
| **Development** | `dev.nix` | `apps.dev.enable` | Docker, VirtualBox, tools |
| **School** | `cours.nix` | `apps.school` | Educational software |
| **Media** | `media.nix` | `apps.media` | VLC, MPV, etc. |
| **Crypto** | `crypto.nix` | `apps.crypto` | Cryptocurrency tools |
| **Desktop Apps** | `desktopsApps.nix` | Desktop | GUI applications |
| **Syncthing** | `syncthing/` | `apps.sync` | File synchronization |

---

## Server Modules (`modules/server/`)

### Core Infrastructure

| Module | Path | Service | Description |
|--------|------|---------|-------------|
| **Options** | `options.nix` | - | Defines `qgroget.services` and `qgroget.backups` |
| **Settings** | `settings.nix` | - | Auto-configures persistence from services |
| **Traefik** | `traefik/default.nix` | `traefik.service` | Reverse proxy, TLS, routing |

### Authentication & Security

| Module | Path | Services | Description |
|--------|------|----------|-------------|
| **SSO** | `SSO/default.nix` | `authelia-qgroget`, `lldap` | Single sign-on with LDAP backend |
| **Security** | `security/` | `crowdsec` | Intrusion prevention (disabled) |

### Media Services

| Module | Path | Service | Port | Type |
|--------|------|---------|------|------|
| **Jellyfin** | `media/video/default.nix` | `jellyfin.service` | 8096 | public |
| **Jellyseerr** | `media/video/jellyseer.nix` | `jellyseerr.service` | 5055 | public |
| **Immich** | `media/photo/default.nix` | `immich-server`, `immich-ml`, `immich-pg` | 2283 | private |

### Media Automation (*arr stack)

| Module | Path | Container | Port | Type |
|--------|------|-----------|------|------|
| **Sonarr** | `arrs/default.nix` | `sonarr` | 9090 | private |
| **Sonarr-Anime** | `arrs/default.nix` | `sonarr-anime` | 8989 | private |
| **Radarr** | `arrs/default.nix` | `radarr` | 7877 | private |
| **Radarr-Anime** | `arrs/default.nix` | `radarr-anime` | 7878 | private |
| **Bazarr** | `arrs/default.nix` | `bazarr` | 6767 | private |
| **Prowlarr** | `arrs/default.nix` | `prowlarr` | 9696 | private |
| **Qui** | `arrs/default.nix` | `qui` | 7476 | public |

### Download Services

| Module | Path | Container | Port | Notes |
|--------|------|-----------|------|-------|
| **qBittorrent** | `downloaders/default.nix` | `qbittorrent` | 8112 | Via Gluetun VPN |
| **qBittorrent-Bis** | `downloaders/default.nix` | `qbittorrent_bis` | 8113 | Via Gluetun VPN |
| **qBittorrent-Nyaa** | `downloaders/default.nix` | `qbittorrent_nyaa` | 8114 | Via Gluetun VPN |
| **Nicotine+** | `downloaders/default.nix` | `nicotine-plus` | 6080 | Soulseek client |
| **Gluetun** | `downloaders/default.nix` | `gluetun` | - | VPN container |

### Password & Credentials

| Module | Path | Container | Port | Type |
|--------|------|-----------|------|------|
| **Vaultwarden** | `password-manager/default.nix` | `vaultwarden` | 4743 | public |

### Backup Services

| Module | Path | Service | Description |
|--------|------|---------|-------------|
| **Restic** | `backup/default.nix` | `restic-*` | Local backups with coordinator |
| **BorgBackup** | `backup/default.nix` | `borgbackup-*` | Remote backups |

### Miscellaneous Services

| Module | Path | Description | Type |
|--------|------|-------------|------|
| **Obsidian** | `misc/obsidian.nix` | Notes publishing | private |
| **Portfolio** | `misc/portfolio.nix` | Personal website | public |
| **File Server** | `misc/fileServer.nix` | File sharing | private |
| **Forgejo** | `misc/forgero.nix` | Git server | private |
| **Syncthing** | `misc/syncthing.nix` | File sync | private |

### DNS & Dashboard

| Module | Path | Service | Description |
|--------|------|---------|-------------|
| **DNS** | `dns/default.nix` | - | DNS services |
| **Dashboard** | `dashboard/default.nix` | - | Homepage/dashboard |

---

## System Modules (`modules/system/`)

| Module | Path | Description |
|--------|------|-------------|
| **Audio** | `audio/audio.nix` | PipeWire configuration |
| **Bluetooth** | `bluetooth/bluetooth.nix` | Bluetooth support |
| **Boot** | `boot/plymouth.nix` | Boot splash screen |
| **Login** | `login/login.nix` | Display manager selection |
| **TPM** | `tpm/tpm.nix` | Trusted Platform Module |
| **Update** | `update/update.nix` | Auto-update configuration |
| **Remote Access** | `remoteAccess.nix` | Tailscale, Sunshine |

---

## Gaming Modules (`modules/game/`)

| Module | Path | Condition | Description |
|--------|------|-----------|-------------|
| **Game** | `game.nix` | `qgroget.nixos.gaming` | Steam, gaming tools |
| **Scripts** | `script.nix` | Gaming | Helper scripts |
| **Steam Import** | `steamImport.nix` | Gaming | Library import |

---

## Shared Modules (`modules/shared/`)

| Module | Path | Description |
|--------|------|-------------|
| **Default** | `default.nix` | Module entry point |
| **Syncthing Settings** | `syncthingSettings.nix` | Folder definitions |

---

## Service Registration Reference

### Complete qgroget.services Attributes

```nix
qgroget.services.<name> = {
  name = "subdomain";           # Required: subdomain.qgroget.com
  url = "http://127.0.0.1:PORT"; # Required: backend URL
  type = "private" | "public";  # Default: "private"
  persistedData = [             # Directories to persist
    "/var/lib/service"
    { directory = "/path"; user = "u"; group = "g"; mode = "0755"; }
  ];
  backupDirectories = [];       # Extra backup paths
  middlewares = [];             # Traefik middlewares
  logPath = "";                 # Log file path
  journalctl = false;           # Use journald logging
  unitName = "";                # Systemd unit name
  traefikDynamicConfig = {};    # Additional Traefik config
};
```

### Middleware Reference

| Middleware | Purpose | Applied To |
|------------|---------|------------|
| `SSO` | Authelia forward auth | Private services |
| `inject-basic-arr` | Basic auth for *arr apps | Sonarr, Radarr, etc. |
| `mtls` | Client certificate (auto) | Private services |

---

## Container Images Reference

| Service | Image |
|---------|-------|
| Sonarr | `lscr.io/linuxserver/sonarr:latest` |
| Radarr | `lscr.io/linuxserver/radarr:latest` |
| Bazarr | `lscr.io/linuxserver/bazarr:latest` |
| Prowlarr | `lscr.io/linuxserver/prowlarr:latest` |
| qBittorrent | `lscr.io/linuxserver/qbittorrent:latest` |
| Gluetun | `qmcgaw/gluetun` |
| Nicotine+ | `ghcr.io/fletchto99/nicotine-plus-docker:latest` |
| Vaultwarden | `docker.io/vaultwarden/server:latest` |
| Qui | `ghcr.io/autobrr/qui:latest` |

---

## Tests Reference

| Test | Path | Run Command |
|------|------|-------------|
| Jellyfin | `tests/jellyfin/` | `nix build .#checks.x86_64-linux.jellyfinTest` |
| Jellyseerr | `tests/jellyseerr/` | `nix build .#checks.x86_64-linux.jellyseerrTest` |

---

_Generated using BMAD Method `document-project` workflow_
