# Strange500's NixOS Configuration

A comprehensive, declarative NixOS configuration flake supporting multiple systems: desktop workstations (Clovis, Septimius), servers (Server), gaming devices (Cube), and an installer ISO. This configuration emphasizes development workflows, security hardening, and reproducible deployments.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Setup
- Install Nix with flakes enabled:
  ```bash
  curl -L https://nixos.org/nix/install | sh -s -- --daemon
  # Restart shell or source profile
  ```
- Ensure experimental features are enabled:
  ```bash
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  ```

### Core Build Commands
- **NEVER CANCEL builds** - NixOS builds can take 15-45 minutes depending on changes (tools fetched from cache). Set timeout to 60+ minutes.
- Test flake syntax and validate configuration:
  ```bash
  nix flake check
  ```
- Build specific host configuration (dry-run, no installation):
  ```bash
  nix build .#nixosConfigurations.Clovis.config.system.build.toplevel
  # Takes 15-45 minutes (tools fetched from cache). NEVER CANCEL. Set timeout to 60+ minutes.
  ```
- Apply configuration to current system:
  ```bash
  sudo nixos-rebuild switch --flake .#hostname
  # Takes 15-45 minutes (tools fetched from cache). NEVER CANCEL. Set timeout to 60+ minutes.
  ```
- Build installer ISO:
  ```bash
  nix build .#nixosConfigurations.installer.config.system.build.isoImage
  # Takes 45-120 minutes. NEVER CANCEL. Set timeout to 150+ minutes.
  ```

### Available Host Configurations
- **Clovis**: Desktop workstation with Hyprland, development tools, VirtualBox
- **Septimius**: Another desktop/workstation configuration
- **Server**: Server configuration with containers, security modules, SSO
- **Cube**: Gaming device (Steam Deck-like) with Jovian-NixOS
- **installer**: Minimal installer ISO with SSH access

### Development Workflow
- Update flake inputs:
  ```bash
  nix flake update
  # Takes about 1 minute or less
  ```
- Format Nix code:
  ```bash
  alejandra .
  # Or use pre-commit hooks (see below)
  ```
- Test configuration changes:
  ```bash
  # Build without switching (faster validation)
  nixos-rebuild build --flake .#hostname
  # Takes 5-15 minutes (tools fetched from cache). NEVER CANCEL. Set timeout to 30+ minutes.
  ```

## Secret Management
- Uses sops-nix with age encryption
- Setup age key for secrets:
  ```bash
  # System is configured for system-level secrets only:
  sudo mkdir -p /var/lib/sops/age
  sudo echo "your-age-key" > /var/lib/sops/age/keys.txt
  ```
- Edit secrets:
  ```bash
  # Uses the show_secret.sh script
  ./show_secret.sh
  # Or manually:
  nix-shell -p sops --run 'sops secrets/secrets.yaml'
  ```

## Remote Installation
- Install to remote host using nix-anywhere:
  ```bash
  nix run nixpkgs#nixos-anywhere -- --flake .#hostname --generate-hardware-config nixos-generate-config ./hardware-configuration.nix root@ip-address
  # Takes 45-120 minutes. NEVER CANCEL. Set timeout to 150+ minutes.
  ```
- Rebuild remote host:
  ```bash
  nixos-rebuild --target-host user@example.com --remote-sudo --ask-sudo-password switch --flake .#hostname
  # Takes 15-45 minutes (tools fetched from cache). NEVER CANCEL. Set timeout to 60+ minutes.
  ```

## Code Quality and Validation

### Pre-commit Hooks
- Install and run pre-commit hooks:
  ```bash
  nix-shell -p pre-commit --run "pre-commit install"
  pre-commit run --all-files
  # Runs alejandra formatter automatically
  ```

### Validation Steps
- **ALWAYS run these before committing changes**:
  ```bash
  # 1. Format code
  alejandra .
  
  # 2. Validate flake
  nix flake check
  # Takes 1-5 minutes
  
  # 3. Test build (choose appropriate host)
  nixos-rebuild build --flake .#Clovis
  # Takes 5-20 minutes (tools fetched from cache). NEVER CANCEL. Set timeout to 45+ minutes.
  
  # 4. Check for common issues
  # Verify secrets are accessible
  nix-shell -p sops --run "sops -d secrets/secrets.yaml" > /dev/null
  
  # Check module imports
  nix eval .#nixosConfigurations.Clovis.config.system.build.toplevel.outPath --show-trace
  ```

### Service Validation Commands
- Check systemd services after applying configuration:
  ```bash
  # Desktop services
  systemctl --user status hyprland-session.target
  systemctl status bluetooth.service
  systemctl status docker.service
  
  # Server services (Server host)
  systemctl status authelia-qgroget.service
  systemctl status traefik.service
  systemctl status crowdsec.service
  systemctl list-units "quadlet-*" --state=running
  
  # Check container logs
  journalctl -u quadlet-<container-name> -f
  ```

### Manual Testing Scenarios
After making changes, ALWAYS test these complete scenarios:

**Desktop Configuration Testing (Clovis/Septimius)**:
1. Build and switch to new configuration
2. Verify Hyprland starts correctly
3. Test basic applications: Firefox, Kitty terminal, file manager
4. Verify development tools work: Git, Docker, VS Code, LunarVim
5. Test secret management: access encrypted files with sops
6. Check Stylix theming applies correctly
7. Verify VirtualBox functionality (Clovis specific)

**Server Configuration Testing (Server)**:
1. Build server configuration  
2. Verify container services start: `systemctl status quadlet-*`
3. Test SSO/authentication via Authelia
4. Verify backup configurations and schedules
5. Check security modules: CrowdSec, firewall bouncer
6. Test Traefik reverse proxy routing
7. Verify media services (Jellyfin, downloaders) if enabled

**Gaming Configuration Testing (Cube)**:
1. Build gaming configuration
2. Verify Steam and gaming services via Jovian-NixOS
3. Test VR functionality if enabled (nixpkgs-xr)
4. Verify controller support
5. Check game synchronization if enabled

**Installer ISO Testing**:
1. Build installer ISO successfully
2. Verify ISO boots in VM
3. Check SSH access with provided key
4. Test basic tools: vim, git, gparted

## Common Configuration Tasks

### Adding a New Host
1. Create directory in `hosts/new-hostname/`
2. Copy existing configuration as template:
   ```bash
   cp -r hosts/Clovis hosts/new-hostname
   ```
3. Update `hosts/new-hostname/configuration.nix`
4. Add to `flake.nix` outputs:
   ```nix
   new-hostname = mkSystem "new-hostname" desktopModules;
   ```
5. Test build:
   ```bash
   nix build .#nixosConfigurations.new-hostname.config.system.build.toplevel
   ```

### Modifying Modules
- Core modules located in `modules/`:
  - `system/`: System-level configurations
  - `desktop/`: Desktop environment settings
  - `server/`: Server-specific modules
  - `apps/`: Application configurations
  - `shared/`: Common configurations

### Configuration Settings
- Global settings in `settings.nix`
- Host-specific settings in `hosts/hostname/settings.nix`
- Key options available via `qgroget.*` namespace

## Troubleshooting

## Troubleshooting

### Build Failures
- Check for syntax errors:
  ```bash
  nix flake check
  ```
- Review build logs for specific errors
- Common issues:
  - Missing secrets (check age key setup)
  - Hardware configuration mismatches
  - Module import conflicts
  - Network timeout issues (use `--option substituters ""` to force local build)

### Secret Access Issues
- Verify age key exists and is readable:
  ```bash
  ls -la /var/lib/sops/age/keys.txt  # System-level (only path used)
  ```
- Check sops configuration in `.sops.yaml`
- Test secret access:
  ```bash
  ./show_secret.sh
  # Or manually decrypt:
  nix-shell -p sops --run "sops -d secrets/secrets.yaml"
  ```
- If secrets fail, regenerate age key and re-encrypt

### Update Failures
- Automatic updates run daily via systemd timer
- Check update service status:
  ```bash
  systemctl status nixos-upgrade.service
  journalctl -u nixos-upgrade.service -f
  ```
- Manual update process:
  ```bash
  cd ~/nixos
  git pull
  nix flake update
  sudo nixos-rebuild switch --flake .#$HOSTNAME
  ```

### Container Issues (Server configuration)
- Check quadlet container status:
  ```bash
  systemctl list-units "quadlet-*"
  systemctl status quadlet-<container-name>
  ```
- View container logs:
  ```bash
  journalctl -u quadlet-<container-name> -f
  podman logs <container-name>
  ```
- Restart container services:
  ```bash
  systemctl restart quadlet-<container-name>
  ```

### Performance Issues
- Check Nix store disk usage:
  ```bash
  nix store gc --dry-run
  # Clean up if needed:
  nix store gc
  ```
- Optimize Nix store:
  ```bash
  nix store optimise
  ```
- Monitor system resources during builds:
  ```bash
  btop  # or htop
  ```

## Timing Expectations
- **Flake check**: 1-5 minutes
- **Build (no changes)**: 1-5 minutes  
- **Build (with changes)**: 5-20 minutes (tools fetched from cache)
- **Full rebuild with updates**: 15-45 minutes (with cache benefits)
- **Installer ISO build**: 45-120 minutes
- **Remote installation**: 45-120 minutes

**CRITICAL**: NEVER CANCEL any build operation. Always set timeouts to double the expected time. NixOS builds are incremental and canceling wastes previous work.

## Repository Structure
```
.
├── flake.nix              # Main flake definition
├── settings.nix           # Global configuration options
├── hosts/                 # Host-specific configurations
│   ├── Clovis/           # Desktop workstation
│   ├── Server/           # Server configuration  
│   ├── Cube/             # Gaming device
│   ├── Septimius/        # Another desktop
│   └── installer/        # Installer ISO
├── modules/              # Reusable configuration modules
│   ├── system/          # System-level modules
│   ├── desktop/         # Desktop environment
│   ├── server/          # Server modules
│   ├── apps/            # Application configs
│   └── shared/          # Common modules
├── home/                # Home Manager configurations
├── secrets/             # Encrypted secrets (sops)
└── .github/workflows/   # CI/CD automation
```

## Key Commands Reference
```bash
# Essential workflows
nix flake check                                    # Validate flake (1-5 min)
sudo nixos-rebuild switch --flake .#hostname       # Apply config (15-45 min, NEVER CANCEL)
nix build .#nixosConfigurations.hostname.config.system.build.toplevel  # Build only (5-20 min, NEVER CANCEL)

# Development
alejandra .                                        # Format Nix code
nix flake update                                   # Update inputs (about 1 minute)
pre-commit run --all-files                        # Run quality checks

# Remote operations  
nixos-rebuild --target-host user@host --remote-sudo --ask-sudo-password switch --flake .#hostname  # Remote rebuild (15-45 min, NEVER CANCEL)

# Secrets
./show_secret.sh                                   # Edit secrets safely

# Shell aliases (available after configuration)
update                                            # Alias for: sudo nixos-rebuild switch --flake ~/nixos#$HOSTNAME
y                                                 # Open yazi file manager
cat                                               # Aliased to bat (syntax highlighting)
lg                                                # Open lazygit
ls                                                # Aliased to eza (modern ls with icons)
nano                                              # Aliased to VS Code
vim                                               # Aliased to LunarVim (lvim)
```

## Shell Environment
The configuration provides a rich Zsh environment with:
- **Starship prompt** with Git integration and system info
- **Oh My Zsh** with plugins: z, fzf, git, extract
- **Auto-suggestions and syntax highlighting** 
- **Tool integration**: Atuin for history, Zoxide for smart cd, Yazi for file management
- **Development tools**: Git with Delta diff, Lazygit, btop for monitoring

## Important Notes
- All builds are incremental - canceling wastes previous work
- Secret management requires proper age key setup before first use
- Desktop configurations require GPU drivers and display manager setup
- Server configurations include container orchestration via Quadlet
- Gaming configurations require additional kernel modules and hardware support
- Always test in a VM or non-production environment first

## GitHub Workflows
- **Automatic flake updates**: Daily at 2 AM UTC via `.github/workflows/update.yml`
- **Pre-commit hooks**: Alejandra formatting enforced via `.pre-commit-config.yaml`
- Updates are automatically committed and pushed if successful