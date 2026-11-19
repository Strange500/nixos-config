# Tempo / edt.qgroget.com — infrastructure only

This change does **not** authorize deployment. Keep the PR draft until the
provisioning checklist below is satisfied. Merging main can trigger automatic
NixOS/Home Manager activation, including the Traefik route.

## Declared service

- `systemd --user` service `tempo.service`, user `hermes` with existing linger.
- Node 24 from the pinned nixpkgs, one process; no container image is assumed.
- `127.0.0.1:3100`, `NODE_ENV=production`, origin `https://edt.qgroget.com`.
  No firewall changes. Port 3100 has no other declared listener in this checkout;
  **live availability must be checked before activation**.
- `qgroget.services.edt`, private route using the existing Traefik `mtls` option,
  production certificate resolver and noindex middleware. Do not remove mTLS for
  OAuth. No DNS or TLS configuration changes outside this declaration.
- `%h/.local/share/tempo/data` (0700), SQLite file 0600, service umask 0077.
  Server `/home` is persisted by `hosts/Server/disk-config.nix`; application
  releases, credentials and data therefore survive root rollback and reboot.
- No secret in Nix, Git or the release. `LoadCredential` reads the raw password
  from `%h/.config/tempo/password` into a private runtime credential directory;
  a small wrapper exports it only to Node. Missing password or a password shorter
  than 12 characters prevents startup. Core dumps are disabled. The service does
  not accept a general environment file that could override the secure binding.

## Private source and immutable release

`Strange500/edt` is private. Anonymous codeload for the pinned commit returns 404;
there is no verified published image. Do not add a GitHub token to a Nix fetcher,
CI derivation or runtime environment, and do not vendor private source into this
infrastructure repository. An authorized workstation builds a separately
provisioned, read-only release. `revision` pins the reviewed app PR #1 commit
`1200cf117074039da39a99f62b76806f0b1d0e17`, not a mutable branch or `latest`.
An update requires changing that file and staging that exact new revision.

Using Node 24 + npm on an authorized workstation:

```sh
# Authenticate/clone edt using your existing authorized Git workflow first.
bash home/tempo/stage-release.sh /path/to/edt /private/staging/releases
python3 tests/tempo/smoke_release.py "$(command -v node)" \
  /private/staging/releases/"$(tr -d '\n' < home/tempo/revision)"
```

The script archives only the pinned committed tree (never checkout `.env`,
SQLite or uncommitted files), installs locked dependencies without lifecycle
scripts, runs application unit tests, builds Vite assets, audits production
dependencies and prunes dev dependencies. It emits a private, read-only release
with `REVISION` and `SHA256SUMS`; the service checks those file hashes before
startup. Checksums detect corruption, not an untrusted publisher: transfer only
from the authorized builder over an authenticated channel. No GitHub access is
needed on the production service. Never overwrite a release in place.

## Required before approval / merge / activation

1. Review/approve app PR https://github.com/Strange500/edt/pull/1 and its pinned
   commit. A later commit is not automatically included here.
2. On the approved host, check that `ss -ltn` has no conflicting listener on
   `127.0.0.1:3100` or `0.0.0.0:3100`. Verify the existing private-route mTLS
   option and client certificate access. No live host check was performed here.
3. Only after explicit authorization, transfer the staged release intact to
   `/home/hermes/.local/share/tempo/releases/<revision>` as `hermes`. Provision
   parent directories 0700 and preserve release directories 0500/files 0400
   (executable bits may remain where originally present). Verify `SHA256SUMS`
   from inside the destination release. Do not point at the working checkout.
4. Securely provision an owner-generated, strong, one-line raw password at
   `/home/hermes/.config/tempo/password` (owner `hermes`, mode 0600, parent 0700).
   This is **not** an `APP_PASSWORD=...` environment file. No real password has
   been generated, installed or committed by this change. Do not print it in
   logs, shell history or review comments. Rotate by replacing the file securely
   and restarting the service; in-memory sessions expire on restart.
5. Prepare a real backup destination and retention policy. Neither a backup
   destination nor a backup credential is invented by this PR.
6. After owner authorization and provisioning, approve/merge infra and use the
   normal deployment workflow. Do not run an ad-hoc switch from this PR review.

Missing releases fail in WorkingDirectory/ExecStartPre, missing credentials fail
in systemd, and invalid passwords fail in the app. There is no insecure fallback
server. Nix evaluation intentionally does not need access to private application
sources; it is **not** proof that the host release or password is provisioned.

## Acceptance after authorized deployment

- `systemctl --user status tempo.service` and journal: healthy, no secrets.
- Loopback `/api/health` returns 200; `/api/state` without session returns 401.
- Validate HTTPS with the real CA and authorized mTLS client, not `curl -k`.
  A client without the required certificate must not reach the application.
- Log in, add a test task, restart, log in again, and confirm persistence.
- Test a reboot and confirm data, credentials and service availability survive.
- Check real browser desktop/mobile behavior and OAuth separately.

Google OAuth is optional for manual agenda/ICS use. It needs the owner's real
Web Client ID, authorized JavaScript origin `https://edt.qgroget.com`, Calendar
API and `calendar.events.readonly` consent. Enter the Client ID/calendar ID in
Tempo settings after login; no server client secret or callback is used. Tokens
stay in browser memory. No fake credentials are provided. Real Google consent
and the owner's ICS feeds remain unverified; see app `docs/DEPLOYMENT.md`.

## Backups and rollback

Use SQLite's backup API while running, or stop `tempo.service` and back up the
**whole** data directory (including any WAL/SHM files) before restarting. Protect
backup copies like the database: feed URLs and calendar contents are sensitive.
Never copy only a live `tempo.sqlite`. Back up the password via the owner's
secret manager, separately from code/artifacts.

Restore with the service stopped, restoring directory 0700/file permissions and
the matching pinned release, then restart and validate. For code rollback revert
the infra revision in a reviewed PR and retain the old immutable release. Database
compatibility must be checked before rolling back; preserve a consistent backup.
This PR does not schedule a backup job or claim a restore rehearsal.

## Local verification

```sh
python3 tests/tempo/test_deployment.py -v
bash -n home/tempo/stage-release.sh
nix eval --raw .#homeConfigurations.hermes.activationPackage.drvPath
nix eval --raw .#nixosConfigurations.Server.config.system.build.toplevel.drvPath
nix build .#homeConfigurations.hermes.activationPackage --no-link
```

The deployment contract test also runs in infrastructure CI without private app
access. The separate release smoke test exercises actual built assets,
authentication, CSRF, production cookie flags, session expiry across restart,
SQLite persistence and permissions, using only temporary synthetic test data.
