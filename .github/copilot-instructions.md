## Quick orientation for AI code edits

This repository is a NixOS configuration (flake) for multiple hosts and a homelab server. The goal of these instructions is to help an AI agent be productive quickly and safely when making changes.

- Root flake: `flake.nix` — exports `nixosConfigurations` (per-host builds) and `checks` (tests). Use `nix flake show` to discover available outputs before making changes.
- Hosts: `hosts/<Hostname>/configuration.nix` (and `hardware-configuration.nix`, `disk-config.nix`, `settings.nix`) — edits here change a specific machine.
- Modules: `modules/` — reusable Nix modules grouped by purpose (e.g., `modules/server`, `modules/desktop`, `modules/apps`). Each module uses `default.nix` (or `options.nix`) and is imported by `flake.nix`.

Key workflows and safe commands
- Inspect available flake outputs:

  nix flake show

- Build and switch a host (replace `YourHost` with the folder name under `hosts/`, e.g. `Server` or `Clovis`):

  sudo nixos-rebuild switch --flake .#YourHost

  If you want to inspect available NixOS configurations first, run `nix flake show` and look under `nixosConfigurations`.

- Run the repository's Nix tests (flake exposes `checks.<system>`):

  nix build .#checks.x86_64-linux.jellyfinTest

Repository-specific patterns and conventions (do not guess — follow these)
- Secrets are stored encrypted in `secrets/secrets.yaml` and managed with `sops` + `sops-nix`. Do NOT attempt to commit plaintext secrets. Keep changes to `secrets/` minimal and only when using the existing SOPS workflow.
- The flake pulls many inputs (see top of `flake.nix`). New features should prefer composing existing inputs (e.g., `sops-nix`, `impermanence`, `declarative-jellyfin`) instead of adding ad-hoc packages.
- Desktop vs Server: `flake.nix` builds different module lists for desktop (`desktopModules`) and server (`serverModules`). When adding services, prefer `modules/server/*` and import through `flake.nix`'s `serverModules`.
- Per-service conventions: services are often defined under `modules/server/*/<service>/default.nix` and expose attributes as `qgroget.services.<name>`. Example: Immich configuration is in `modules/server/media/photo/default.nix` and registers `qgroget.services.immich` and `systemd.services."immich-server"`.

Integration points & external dependencies
- Traefik/Ingress: many services rely on `traefik` dynamic configs (see `modules/server/*` and `services.*.traefikDynamicConfig`).
- Containers: `virtualisation.quadlet` containers are used (see Immich's `immich-pg` container in the Immich module). If changing container images/volumes, update the container config and the systemd service preStart hooks accordingly.
- SOPS and runtime secrets: some services use systemd credential injection with `LoadCredential` (see Immich module). Respect that pattern and avoid baking secrets into `/nix/store`.

Examples the agent can perform safely (small, discoverable edits)
- Add a package to a host: update `home.packages` in `home.nix` or `modules/apps/desktopsApps.nix` for cross-host reuse.
- Tweak Immich settings: edit `modules/server/media/photo/default.nix` which already contains the service object and systemd `preStart` logic.

What to avoid / security warnings
- Never write decrypted secrets to disk or commit them.
- Avoid running helper scripts that access secrets (there is a `show_secret.sh` script — do not execute it).

Developer tips for testing and verification
- After small module changes, run `nix flake show` and `nix build` for the targeted flake output (or `nixos-rebuild switch --flake .#Host`) on a test machine or VM.
- Use the flake's `checks` (e.g., `checks.x86_64-linux.jellyfinTest`) to run the project's NixOS tests.

Files to consult for structure & examples
- `flake.nix` — entrypoint and host wiring
- `README.md` — project overview and quick start
- `hosts/*/configuration.nix` — per-host system configs
- `modules/` — where reusable modules live (e.g., `modules/server/media/photo/default.nix`)
- `secrets/` — encrypted secrets (do not decrypt or commit plaintext)

If anything is ambiguous, ask the maintainer which host to target (host folder name under `hosts/`) and whether you should run a rebuild locally or open a PR with the changelist only.

---
If you want, I can tighten this further (shorter examples, add common grep patterns, or include a brief check-list for making safe changes). What would you like improved or expanded?
