<div align="center">

![QGroget](./modules/logo/assets/logo_text.png)

**NixOS Configuration for QGroget Infrastructure**

*Reproducible, declarative systems for desktop computing and homelab services*

![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Flakes](https://img.shields.io/badge/Nix_Flakes-Enabled-blue?style=for-the-badge)

</div>

---

## 🏠 Why This Configuration Exists

After being a distro hopper for a year and a half - bouncing from basic Debian to Ubuntu (not customizable enough!), to Arch (breaking after each update 💥), and EndeavourOS - I finally discovered **NixOS**! 🎉 

It's highly customizable yet nearly unbreakable. Now I'm exploring the Nix world and trying different things, which led to this configuration serving as the foundation for **QGroget** - a personal computing ecosystem focused on reproducibility and self-hosting.

**The Journey:** From distro chaos to NixOS zen 🧘‍♂️  
**The Goal:** Create identical, reliable systems across multiple machines while maintaining a powerful homelab infrastructure.

**The Problem:** Setting up and maintaining multiple computers with consistent configurations is tedious and error-prone (especially after yet another Arch update breaks everything).

**The Solution:** NixOS with flakes provides declarative, version-controlled system configurations that ensure every machine is identical and reproducible - no more broken systems!

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

*For detailed installation and customization instructions, check the configuration files or open an issue for specific questions.*



setting up

pywalfox install

ln -sf ~/.cache/wal/dank-pywalfox.json ~/.cache/wal/colors.json