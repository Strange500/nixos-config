# Jellyfin configuration with Jellarr

Jellarr is a declarative REST API client for Jellyfin, **not a replacement media
server**. Jellyfin, its data directory, users, libraries, media, proxy route,
hardware groups and backups remain in place. The unused declarative-jellyfin
input/module and its obsolete password-management options are removed.

## Read-only production inventory

Inspected on 2026-11-22 over SSH, without restarting or changing production:

- `jellyfin.service` is active, runs as `jellyfin`, listens on port 8096.
- Public API reports version `12.4.0`, server name `QGRoget`, ID
  `68fb5b2c9433451fa16eb7e29139e7f2`, completed startup wizard.
- Data/config/cache/log directories are `/var/lib/jellyfin`,
  `/var/lib/jellyfin/config`, `/var/cache/jellyfin`, `/var/lib/jellyfin/log`.
- `/var/lib/jellyfin` and its persisted directory are mode 0700 and not readable
  by the SSH account. No privileged filesystem bypass was attempted.
- Jellyfin's public `GET /Branding/Configuration` returns empty login disclaimer
  and custom CSS, and `SplashscreenEnabled = true`. These exact values are the
  managed `branding` block. Jellarr itself reads/writes the authenticated
  `/System/Configuration/Branding`, so with the current 401 even this block will
  fail to reconcile until the token is fixed.
- **The user-supplied API token currently returns HTTP 401** on authenticated
  reads of `/System/Configuration`, `/System/Configuration/encoding`,
  `/Library/VirtualFolders`, `/Users` and `/Plugins`. The token was compared with
  the original user message without displaying it. No authenticated export was
  possible. A successful public branding read does not validate authentication.

Therefore libraries/paths/options, encoding/acceleration, plugin repositories
and configuration, user policies, system/network settings and passwords could
**not** be migrated from runtime. Existing values are deliberately left unmanaged;
old repository defaults are not a substitute for an observed configuration.
Jellarr's typed Nix schema also does not expose every Jellyfin setting (for
example server identity and network settings); those stay in Jellyfin's persisted
configuration. Password hashes cannot be used as Jellarr plaintext passwords.
No full private-state snapshot was possible with the available permissions.

## Packaging

The `jellarr` flake input supplies the module (typed config schema and unit
generation). Its bundled `nix/package.nix` pins a `fetchPnpmDeps` hash that no
longer matches current nixpkgs — CI failed with a hash mismatch — so
`modules/server/media/video/jellarr-package.nix` wraps the **official v0.1.0
release bundle** instead, pinned by sha256. That artifact is byte-identical to a
`pnpm build` of the pinned commit (verified locally), so the executed code is the
reviewed revision. The module's `ExecStart` is overridden accordingly; its
`bootstrap` stays disabled.

## Secret storage

`secrets/jellarr.env` is a SOPS-encrypted dotenv file, encrypted to the **existing**
age recipient from `.sops.yaml`. The private age key was neither needed nor
exported. The existing `secrets/secrets.yaml` and its ciphertext are untouched.

`sops-nix` decrypts the whole dotenv file to `/run/secrets/server/jellarr/env`
with mode 0400. Only systemd reads it as `EnvironmentFile`; Nix evaluation,
generated YAML and the Nix store contain no plaintext token. The supported
variable is `JELLARR_API_KEY`. Do not use `builtins.readFile` on decrypted secrets.

On a trusted machine with the existing age identity, correct/rotate the token
with `sops --input-type dotenv --output-type dotenv secrets/jellarr.env`.
Keep the `JELLARR_API_KEY` assignment and never paste the decrypted file into
terminal output, issues or PRs. Register/rotate a key in the Jellyfin admin UI;
this PR intentionally disables upstream's SQLite-based bootstrap, which would
stop Jellyfin and modify its database.

## Before enabling in production / marking the PR ready

1. Resolve the HTTP 401 and validate authenticated reads without logging headers.
2. Take a consistent Jellyfin backup using the existing backup mechanism. No
   backup or service interruption was performed by this change.
3. From a trusted session where the token is already provided securely via the
   environment, run `jellarr dump --baseUrl http://127.0.0.1:8096` to a private
   file (mode 0600). The upstream dump is experimental; plugin settings can
   contain credentials, so **never commit the raw dump**.
4. Review the export, add only verified supported non-secret fields to
   `services.jellarr.config`, and keep credentials in SOPS runtime files. Do not
   invent users, passwords, libraries, repositories or GPU settings.
5. Run `nix build .#checks.x86_64-linux.jellyfinTest --no-link -L` and evaluate/build
   the Server configuration. Review the PR CI results before merging.
6. Deployment is a separate action: this PR does not rebuild/switch production.
   After an approved deployment, verify `jellarr.service`, its hourly timer,
   Jellyfin health and the actual authenticated configuration. The oneshot also
   runs at boot; an invalid token causes reconciliation to fail, not a fallback
   database write. Review the exact deployed configuration before applying.

The VM test keeps a real Jellyfin health check, then uses an explicit fake REST
fixture and dummy token to exercise the actual packaged Jellarr binary twice.
That tests integration, not access to or a successful migration of production.

## Verification performed for this PR

- `alejandra` clean, `git diff --check` clean.
- `nix eval` of `nixosConfigurations.Server` and of the `jellyfinTest` check.
- Upstream source at the pinned revision: `pnpm build` + `pnpm test`
  (397 tests passed).
- The evaluated production `services.jellarr.config` was fed to that compiled
  bundle against the test fixture: first run updated branding, second run
  reported "already up to date" (idempotent).
- Not executed here: the `nixosTest` VM itself (this sandbox has no kernel
  namespaces for the Nix sandbox) and a real `nix build` of the Server toplevel.
  Both are wired into CI (`jellarr` job and `build Server`); production was not
  rebuilt or switched.
