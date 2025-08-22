# 🖥️ QGroget Server Infrastructure

<div align="center">

![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Podman](https://img.shields.io/badge/Podman-892CA0?style=for-the-badge&logo=podman&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)

*Self-hosted infrastructure with immutable NixOS setup*

**🔒 Secure • 🚀 Scalable • 📦 Containerized**

</div>

---

## 🏗️ Architecture Overview

The QGroget server infrastructure is built on NixOS with a containerized architecture using Podman and Quadlet for service orchestration. The system features an immutable design with tmpfs root filesystem and persistent data management through BTRFS subvolumes.

### Core Components

- **Operating System**: NixOS with immutable tmpfs root
- **Container Runtime**: Podman with rootless containers
- **Service Discovery**: Traefik reverse proxy with automatic SSL
- **Storage**: BTRFS with VirtioFS mounts for shared storage
- **Security**: CrowdSec intrusion prevention, Authelia SSO
- **Backup**: Automated backup solutions with retention policies

## 📋 System Requirements

- **CPU**: x86_64 with virtualization support
- **RAM**: Minimum 8GB, recommended 16GB+
- **Storage**: 
  - Primary disk: 100GB+ for system (BTRFS)
  - Secondary disk: 500GB+ for containers (ext4)
  - Shared mounts: Variable based on media requirements
- **Network**: Static IP configuration recommended

## 🔧 Infrastructure Configuration

### Host Configuration

The server is configured through several key files:

- **`configuration.nix`**: Main system configuration
- **`settings.nix`**: QGroget-specific server settings
- **`disk-config.nix`**: Disk partitioning and filesystem setup
- **`hardware-configuration.nix`**: Hardware-specific settings

### Key Settings

```nix
# Primary server configuration in settings.nix
qgroget = {
  server = {
    domain = "qgroget.com";          # Your domain
    network.ip = "192.168.0.34";     # Server IP
    containerDir = "/etc/containersConfig";  # Container configs
    mediaDir = "/mnt/media";         # Media storage path
    test.enable = false;             # Test mode
  };
  nixos = {
    auto-update = false;             # Automatic updates
    isDesktop = false;               # Server-only mode
    remote-access.enable = true;     # SSH access
  };
};
```

## 🚀 Available Services

### 📺 Media Services

| Service | Description | Port | Path |
|---------|-------------|------|------|
| **Jellyfin** | Media server for videos/music | 8096 | `/video` |
| **Immich** | Photo management and sharing | 2283 | `/photo` |
| **Jellyseerr** | Media request management | - | `/video/jellyseer.nix` |

### ⬇️ Download Services

| Service | Description | Port | Module |
|---------|-------------|------|--------|
| **qBittorrent** (x3) | BitTorrent clients with VPN | 8112-8114 | `/downloaders` |
| **NicotinePlus** | Soulseek P2P client | 6080 | `/downloaders` |
| **Gluetun** | VPN gateway for downloaders | - | `/downloaders` |

### 🔍 *Arr Stack (Media Automation)

| Service | Description | Port | Module |
|---------|-------------|------|--------|
| **Sonarr** | TV show management | 9090 | `/arrs` |
| **Sonarr Anime** | Anime-specific management | 8989 | `/arrs` |
| **Radarr** | Movie management | 7877 | `/arrs` |
| **Radarr Anime** | Anime movie management | 7878 | `/arrs` |
| **Bazarr** | Subtitle management | 6767 | `/arrs` |
| **Prowlarr** | Indexer management | 9696 | `/arrs` |
| **FlareSolverr** | CloudFlare solver | 8191 | `/arrs` |

### 🔐 Security & Authentication

| Service | Description | Module |
|---------|-------------|--------|
| **Authelia** | SSO and 2FA provider | `/SSO` |
| **CrowdSec** | Intrusion prevention system | `/security` |
| **Fail2Ban** | Brute force protection | Built-in |

### 🌐 Infrastructure Services

| Service | Description | Module |
|---------|-------------|--------|
| **Traefik** | Reverse proxy and load balancer | `/traefik` |
| **Pi-hole** | DNS-based ad blocker | `/dns` |
| **Homepage** | Service dashboard | `/dashboard` |
| **Vaultwarden** | Password manager | `/password-manager` |

### 💾 Backup & Sync

| Service | Description | Module |
|---------|-------------|--------|
| **Restic** | Automated backups | `/backup` |
| **Syncthing** | File synchronization | `/misc` |

### 🛠️ Miscellaneous Services

| Service | Description | Module |
|---------|-------------|--------|
| **Forgero** | Custom application | `/misc` |
| **Obsidian** | Note-taking vault | `/misc` |
| **File Server** | HTTP file sharing | `/misc` |
| **Portfolio** | Personal website | `/misc` |

## 🗂️ Storage Architecture

### Mount Points

The server uses VirtioFS for efficient file sharing:

```nix
fileSystems = {
  "/mnt/media"  = { device = "media";  fsType = "virtiofs"; };   # General media
  "/mnt/music"  = { device = "music";  fsType = "virtiofs"; };   # Music library
  "/mnt/share"  = { device = "share";  fsType = "virtiofs"; };   # Shared files
  "/mnt/immich" = { device = "immich"; fsType = "virtiofs"; };   # Photo storage
  "/persist"    = { device = "persist"; fsType = "virtiofs"; };  # Persistent data
};
```

### Disk Configuration

- **Primary Disk (/dev/vda)**: System partitions with BTRFS
  - Boot partition (1MB)
  - ESP partition (500MB, FAT32)
  - System partition (remaining space, BTRFS)
    - `@nix` subvolume → `/nix`
    - `@var-log` subvolume → `/var/log`
    - `@home` subvolume → `/home`

- **Secondary Disk (/dev/vdb)**: Container storage
  - Single ext4 partition → `/var/lib/containers`

- **Root Filesystem**: tmpfs (4GB, mode=755)
  - Provides immutable system behavior
  - Persistent data handled through `/persist`

## 🔒 Security Features

### Access Control

- **SSH**: Key-based authentication only
- **Fail2Ban**: Automatic IP banning for failed attempts
- **Firewall**: Restrictive rules with specific port allowances
- **User Management**: Non-mutable users with specific configurations

### Service Security

- **Authelia SSO**: Centralized authentication with 2FA
- **CrowdSec**: Real-time intrusion detection and prevention
- **Container Isolation**: Rootless Podman with user namespaces
- **Secret Management**: SOPS-encrypted secrets with age keys

### Network Security

- **Traefik TLS**: Automatic SSL certificate management
- **Internal Networking**: Service-to-service communication via Podman networks
- **VPN Integration**: Dedicated VPN containers for download services

## 🚀 Deployment Guide

### Prerequisites

1. **NixOS Installation**: Fresh NixOS system with flakes enabled
2. **Hardware**: Meet minimum system requirements
3. **Network**: Configure static IP and domain DNS
4. **Storage**: Prepare disks according to `disk-config.nix`

### Initial Deployment

1. **Clone Repository**:
   ```bash
   git clone https://github.com/Strange500/nixos-config.git ~/nixos-config
   cd ~/nixos-config
   ```

2. **Configure Hardware**:
   ```bash
   # Generate hardware configuration
   nixos-generate-config --show-hardware-config > hosts/Server/hardware-configuration.nix
   ```

3. **Customize Settings**:
   Edit `hosts/Server/settings.nix` with your specific configuration:
   ```nix
   qgroget = {
     server = {
       domain = "your-domain.com";
       network.ip = "your-server-ip";
     };
   };
   ```

4. **Setup Age Keys**:
   ```bash
   mkdir -p ~/.config/sops/age
   echo "your-age-private-key" > ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

5. **Deploy System**:
   ```bash
   sudo nixos-rebuild switch --flake .#Server
   ```

### Remote Deployment

For remote deployment using nixos-anywhere:

```bash
nix run nixpkgs#nixos-anywhere -- --flake .#Server \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  root@your-server-ip
```

## 🔧 Configuration & Customization

### Service Management

Services are managed through the QGroget configuration system:

```nix
# Add custom service
qgroget.services.myservice = {
  name = "myservice";
  url = "http://localhost:8080";
  type = "private";  # or "public"
  middlewares = [ "authelia@file" ];
};
```

### Module Structure

Each service is organized in its own module under `modules/server/`:

```
modules/server/
├── default.nix          # Main module definition
├── media/               # Media services
├── arrs/                # *Arr stack
├── downloaders/         # Download clients
├── security/            # Security services
├── traefik/             # Reverse proxy
└── ...
```

### Adding New Services

1. **Create Module**: Add service configuration in appropriate subdirectory
2. **Define Container**: Use Podman Quadlet for container management
3. **Configure Routing**: Add Traefik routing rules
4. **Setup Persistence**: Configure data persistence if needed
5. **Add Secrets**: Use SOPS for sensitive configuration

### Environment Variables

Set environment-specific configuration:

```nix
# Enable test mode (exposes Traefik dashboard)
qgroget.server.test.enable = true;

# Configure automatic updates
qgroget.nixos.auto-update = true;

# Enable Tailscale for remote access
qgroget.nixos.remote-access.tailscale.enable = true;
```

## 🔍 Monitoring & Maintenance

### System Monitoring

- **Systemd Services**: Monitor with `systemctl status service-name`
- **Container Health**: Check with `podman ps` and `podman logs`
- **Resource Usage**: Use `btop` or `htop` for real-time monitoring
- **Storage**: Monitor BTRFS usage with `btrfs filesystem usage /`

### Log Management

Logs are managed through systemd-journald:

```bash
# View service logs
journalctl -u service-name -f

# Container logs via Podman
podman logs -f container-name

# System logs
journalctl -f
```

### Backup Operations

Automated backups are configured per service:

```nix
qgroget.backups.myservice = {
  paths = [ "/path/to/data" ];
  systemdUnits = [ "myservice.service" ];
};
```

### Updates & Maintenance

1. **System Updates**: Managed via `nixos-rebuild switch`
2. **Container Updates**: Automatic with Quadlet service restarts
3. **Backup Verification**: Regular backup integrity checks
4. **Security Updates**: CrowdSec and system security patches

## 🛠️ Troubleshooting

### Common Issues

#### Container Startup Failures

```bash
# Check container status
podman ps -a

# View container logs
podman logs container-name

# Restart container
systemctl restart container-name.service
```

#### Storage Issues

```bash
# Check BTRFS health
btrfs filesystem show
btrfs scrub status /

# Check mount points
mount | grep virtiofs
```

#### Network Connectivity

```bash
# Test Traefik routing
curl -H "Host: service.domain.com" http://localhost:80

# Check firewall rules
iptables -L

# Verify DNS resolution
dig service.domain.com
```

#### Service Access Issues

1. **Check Authelia Configuration**: Verify SSO settings
2. **Verify Traefik Rules**: Ensure proper routing configuration
3. **Container Networking**: Check Podman network connectivity
4. **SSL Certificates**: Verify certificate generation and renewal

### Performance Optimization

- **Container Resources**: Adjust memory and CPU limits
- **Storage Optimization**: Use BTRFS compression and deduplication
- **Network Tuning**: Optimize Traefik configuration for load
- **Backup Scheduling**: Spread backup operations across time

## 📚 References

- [NixOS Server Guide](https://nixos.wiki/wiki/NixOS_on_ARM/Installation)
- [Podman Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [Traefik Configuration Reference](https://doc.traefik.io/traefik/)
- [BTRFS Wiki](https://btrfs.wiki.kernel.org/)
- [Authelia Documentation](https://www.authelia.com/overview/prologue/introduction/)

## 📄 License

This server configuration is part of the Strange500 NixOS configuration, licensed under the MIT License.

---

<div align="center">

**Built with ❤️ using NixOS and the power of declarative configuration**

</div>