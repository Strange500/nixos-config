<div align="center">

![QGroget](./qgroget-logo.png)

**NixOS Configuration for QGroget Infrastructure**

*Reproducible, declarative systems for desktop computing and homelab services*

![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Flakes](https://img.shields.io/badge/Nix_Flakes-Enabled-blue?style=for-the-badge)

</div>

---

## 🏠 Why This Configuration Exists

This NixOS configuration serves as the foundation for **QGroget** - a personal computing ecosystem focused on reproducibility and self-hosting. The goal is simple: create identical, reliable systems across multiple machines while maintaining a powerful homelab infrastructure.

**The Problem:** Setting up and maintaining multiple computers with consistent configurations is tedious and error-prone.

**The Solution:** NixOS with flakes provides declarative, version-controlled system configurations that ensure every machine is identical and reproducible.

## 🖥️ What's Inside

### Desktop Systems
- **Modern Development Environment**: Hyprland window manager, Kitty terminal, LunarVim editor
- **Security-First**: Age-encrypted secrets management, secure SSH configurations
- **Performance Optimized**: Tailored for development workflows and productivity

### QGroget Homelab Server
The server configuration powers a comprehensive self-hosted infrastructure at **qgroget.com**:

- **🎬 Media Management**: Jellyfin, Sonarr, Radarr, Bazarr for automated media collection and streaming
- **📱 Personal Cloud**: Immich for photo management, Navidrome for music streaming
- **🔐 Security & Auth**: Authelia SSO, CrowdSec security, Vaultwarden password management  
- **📁 File Services**: Syncthing synchronization, file sharing capabilities
- **🌐 Web Services**: Traefik reverse proxy, portfolio hosting, Obsidian notes
- **🔄 Backup & Sync**: Automated backup solutions and cross-device synchronization

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/Strange500/nixos-config.git ~/nixos

# Build and switch (replace with your hostname)
sudo nixos-rebuild switch --flake ~/nixos#your-hostname
```

## 🛠️ Key Features

- **Reproducible**: Every system build is identical and version-controlled
- **Declarative**: Infrastructure as code - no hidden state or manual configurations  
- **Secure**: Built-in secrets management and security hardening
- **Modular**: Easy to customize and extend for different use cases
- **Self-Hosted**: Complete homelab infrastructure with minimal external dependencies

---

*For detailed installation and customization instructions, see the [installation guide](docs/installation.md).*
