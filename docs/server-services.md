# QGroget NixOS Configuration - Server Services

**Date:** 2026-01-06
**Document Type:** Homelab Services Reference

## Overview

The QGroget server hosts a comprehensive self-hosted infrastructure at **qgroget.com**. All services are managed declaratively via NixOS modules in `modules/server/`.

---

## Service Categories

```
┌─────────────────────────────────────────────────────────────────┐
│                        TRAEFIK                                   │
│              (Reverse Proxy, TLS, Routing)                       │
│                 https://*.qgroget.com                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
    │ PUBLIC  │    │ PRIVATE │    │  ADMIN  │
    │SERVICES │    │SERVICES │    │SERVICES │
    └─────────┘    └─────────┘    └─────────┘
    - Jellyfin     - Immich       - Sonarr
    - Jellyseerr   - Authelia     - Radarr
    - Vaultwarden  - Obsidian     - Prowlarr
    - Portfolio    - Syncthing    - qBittorrent
    - Qui          - Dashboard
```

---

## Media Services

### Jellyfin (Video Streaming)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/media/video/default.nix` |
| **URL** | `jellyfin.qgroget.com` |
| **Port** | 8096 |
| **Type** | Public |
| **Data Path** | `/var/lib/jellyfin`, `/mnt/data/media` |

**Features:**
- Declarative user management via `declarative-jellyfin`
- Hardware transcoding (AMD GPU)
- Automated library scanning

**Configuration:**
```nix
qgroget.server.jellyfin = {
  enable = true;
  users = {
    admin = {
      mutable = false;
      hashedPasswordSecret = config.sops.secrets."server/jellyfin/user/admin/password".path;
      permissions.isAdministrator = true;
    };
    strange = {
      mutable = true;
      hashedPasswordSecret = config.sops.secrets."server/jellyfin/user/strange/password".path;
    };
  };
};
```

### Jellyseerr (Media Requests)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/media/video/jellyseer.nix` |
| **URL** | `jellyseerr.qgroget.com` |
| **Port** | 5055 |
| **Type** | Public |

**Purpose:** Media request management integrated with Sonarr/Radarr.

### Immich (Photo Management)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/media/photo/default.nix` |
| **URL** | `immich.qgroget.com` |
| **Port** | 2283 |
| **Type** | Private (SSO) |
| **Data Path** | `/mnt/data/immich` |

**Components:**
- `immich-server` - Main API server
- `immich-machine-learning` - AI features (face recognition, CLIP)
- `immich-pg` - PostgreSQL with pgvector (Quadlet container)

**Features:**
- OAuth via Authelia
- Machine learning: face detection, smart search
- Automated library scanning
- Database backups (daily, 14 retained)

**Key Configuration:**
```nix
immichConfig = {
  oauth = {
    enabled = true;
    autoLaunch = true;
    issuerUrl = "https://auth.qgroget.com/.well-known/openid-configuration";
    clientId = "...";
  };
  machineLearning = {
    clip.modelName = "ViT-B-32__openai";
    facialRecognition.modelName = "buffalo_l";
  };
};
```

---

## Media Automation (*arr Stack)

All *arr services run as Podman Quadlet containers.

### Sonarr (TV Shows)

| Property | Value |
|----------|-------|
| **URL** | `sonarr.qgroget.com` |
| **Port** | 9090 |
| **Type** | Private (SSO + Basic Auth) |
| **Container** | `sonarr` |

### Sonarr-Anime

| Property | Value |
|----------|-------|
| **URL** | `sonarr-anime.qgroget.com` |
| **Port** | 8989 |
| **Type** | Private (SSO + Basic Auth) |
| **Container** | `sonarr-anime` |

### Radarr (Movies)

| Property | Value |
|----------|-------|
| **URL** | `radarr.qgroget.com` |
| **Port** | 7877 |
| **Type** | Private (SSO + Basic Auth) |
| **Container** | `radarr` |

### Radarr-Anime

| Property | Value |
|----------|-------|
| **URL** | `radarr-anime.qgroget.com` |
| **Port** | 7878 |
| **Type** | Private (SSO + Basic Auth) |
| **Container** | `radarr-anime` |

### Bazarr (Subtitles)

| Property | Value |
|----------|-------|
| **URL** | `bazarr.qgroget.com` |
| **Port** | 6767 |
| **Type** | Private (SSO + Basic Auth) |
| **Container** | `bazarr` |

### Prowlarr (Indexer Manager)

| Property | Value |
|----------|-------|
| **URL** | `prowlarr.qgroget.com` |
| **Port** | 9696 |
| **Type** | Private (SSO + Basic Auth) |
| **Container** | `prowlarr` |

### Qui (Autobrr Web UI)

| Property | Value |
|----------|-------|
| **URL** | `qui.qgroget.com` |
| **Port** | 7476 |
| **Type** | Public |
| **Container** | `qui` |

---

## Download Services

### qBittorrent (Primary)

| Property | Value |
|----------|-------|
| **URL** | `qbittorrent.qgroget.com` |
| **Port** | 8112 |
| **VPN Port** | 30402 |
| **Container** | `qbittorrent` |

**VPN:** Routes through Gluetun container for privacy.

### qBittorrent-Bis (Secondary)

| Property | Value |
|----------|-------|
| **Port** | 8113 |
| **VPN Port** | 40656 |
| **Container** | `qbittorrent_bis` |

### qBittorrent-Nyaa (Anime)

| Property | Value |
|----------|-------|
| **Port** | 8114 |
| **VPN Port** | 59078 |
| **Container** | `qbittorrent_nyaa` |

### Nicotine+ (Soulseek)

| Property | Value |
|----------|-------|
| **Port** | 6080 |
| **Container** | `nicotine-plus` |

**Purpose:** P2P music sharing via Soulseek network.

### Gluetun (VPN Gateway)

| Property | Value |
|----------|-------|
| **Container** | `gluetun` |

**Purpose:** Provides VPN tunnel for download clients.

---

## Authentication & Security

### Authelia (SSO)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/SSO/default.nix` |
| **URL** | `auth.qgroget.com` |
| **Port** | 9091 |
| **Service** | `authelia-qgroget.service` |

**Features:**
- OIDC provider (for Immich, etc.)
- Forward auth for Traefik
- TOTP 2FA support
- LDAP backend (LLDAP)

**Access Control Example:**
```nix
access_control.rules = [
  {
    domain = "sonarr.qgroget.com";
    policy = "two_factor";
    subject = ["group:admin"];
  }
];
```

### LLDAP (User Directory)

| Property | Value |
|----------|-------|
| **Service** | `lldap.service` |

**Purpose:** Lightweight LDAP server for user management.

### Vaultwarden (Password Manager)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/password-manager/default.nix` |
| **URL** | `vaultwarden.qgroget.com` |
| **Port** | 4743 |
| **Type** | Public |
| **Container** | `vaultwarden` |

**Configuration:**
- Signups disabled
- Invitations disabled
- WebSocket enabled

---

## Infrastructure Services

### Traefik (Reverse Proxy)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/traefik/default.nix` |
| **URL** | `proxy.qgroget.com` |
| **Ports** | 80, 443 |

**Features:**
- Automatic Let's Encrypt certificates
- mTLS for private services
- Dynamic configuration from `qgroget.services`
- Access logging

**TLS Configuration:**
```nix
# Public services: standard TLS
# Private services: mTLS with client certificate
tls = {
  certResolver = "production";  # or "staging" for testing
} // lib.optionalAttrs (service.type == "private") {
  options = "mtls";
};
```

### Restic (Local Backups)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/backup/default.nix` |
| **Repo Path** | `/persist/backup/restic` |

**Backup Definitions:**
```nix
qgroget.backups.vaultwarden = {
  paths = ["${containerDir}/vaultwarden"];
  systemdUnits = ["vaultwarden.service"];
};
```

### BorgBackup (Remote Backups)

| Property | Value |
|----------|-------|
| **Target** | Remote backup server |

**Backed Up Directories:**
- `/persist/backup`
- `/mnt/data/immich/upload`
- Selected media directories

---

## Miscellaneous Services

### Portfolio (Personal Website)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/misc/portfolio.nix` |
| **URL** | `portfolio.qgroget.com` (or root) |
| **Type** | Public |

### Obsidian Publish

| Property | Value |
|----------|-------|
| **Module** | `modules/server/misc/obsidian.nix` |
| **Type** | Private |

**Purpose:** Self-hosted notes publishing.

### Syncthing (Server)

| Property | Value |
|----------|-------|
| **Module** | `modules/server/misc/syncthing.nix` |
| **Type** | Private |

**Purpose:** File synchronization between devices.

### File Server

| Property | Value |
|----------|-------|
| **Module** | `modules/server/misc/fileServer.nix` |
| **Type** | Private |

**Purpose:** File sharing/serving.

---

## Network Configuration

### Ports Summary

| Port | Service | Protocol |
|------|---------|----------|
| 22 | SSH | TCP |
| 80 | Traefik HTTP | TCP |
| 443 | Traefik HTTPS | TCP |
| 2283 | Immich | TCP |
| 4743 | Vaultwarden | TCP |
| 5055 | Jellyseerr | TCP |
| 6080 | Nicotine+ | TCP |
| 6767 | Bazarr | TCP |
| 7476 | Qui | TCP |
| 7877 | Radarr | TCP |
| 7878 | Radarr-Anime | TCP |
| 8080 | Traefik Dashboard | TCP |
| 8096 | Jellyfin | TCP |
| 8112-8114 | qBittorrent instances | TCP |
| 8989 | Sonarr-Anime | TCP |
| 9090 | Sonarr | TCP |
| 9091 | Authelia | TCP |
| 9696 | Prowlarr | TCP |

### DNS

Domain: `qgroget.com`
- All services accessible at `<service>.qgroget.com`
- Wildcard certificate via Let's Encrypt

---

## Data Paths

| Service | Path | Purpose |
|---------|------|---------|
| Jellyfin | `/var/lib/jellyfin` | Configuration |
| Jellyfin | `/mnt/data/media` | Media files |
| Immich | `/mnt/data/immich` | Photos/videos |
| *arr stack | `${containerDir}/<service>` | Configuration |
| Vaultwarden | `${containerDir}/vaultwarden` | Vault data |
| Traefik | `/var/lib/traefik` | Certificates, config |
| Backups | `/persist/backup/restic` | Restic repositories |

---

## Secrets Required

| Secret Path | Used By |
|-------------|---------|
| `server/jellyfin/user/*/password` | Jellyfin |
| `server/traefik/clientCaCert` | Traefik mTLS |
| `server/authelia/*` | Authelia (JWT, OIDC, SMTP) |
| `server/lldap/*` | LLDAP |
| `server/vaultwarden/*` | Vaultwarden |
| `server/restic/repoPassword` | Restic backups |
| `server/borg/repoPassword` | Borg backups |
| `server/immich/db_password` | Immich PostgreSQL |
| `server/arr-basic-auth` | *arr Basic Auth |

---

_Generated using BMAD Method `document-project` workflow_
