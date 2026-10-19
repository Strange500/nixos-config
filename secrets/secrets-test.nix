# Fake secret VALUES for nixosTest VMs, consumed by tests/lib/sops-mock.nix.
#
# THIS FILE MUST NEVER CARRY A REAL CREDENTIAL. Every value here is a
# placeholder whose only job is to exist on disk at a plausible-looking path
# so services can boot in a test VM.
#
# It is a Nix attrset rather than YAML on purpose: the harness feeds it
# straight to `pkgs.writeText`, so no YAML parser is involved (sops-nix itself
# cannot read a plain file — sops-install-secrets always decrypts).
#
# Keep the key tree in LOCKSTEP with the real secrets/secrets.yaml: sops-mock
# asserts loudly if a module declares `sops.secrets."x"` that has no entry
# here, so a missing value is a hard test failure rather than a silent empty
# file. Add new modules' secrets here as they gain tests.
let
  # Generic filler: fine for anything only ever read as an opaque string by the
  # service's own config (API tokens, passwords, hmac keys...).
  fake = "fake-test-value";
in {
  "github_token" = fake;
  "git/ssh/private" = fake;
  "ssh/private" = fake;
  "firefox/certFilePKCS12.p12" = fake;
  "networking/eduroam/identity" = fake;
  "networking/eduroam/password" = fake;
  "tailscale/oauth/client" = fake;
  "tailscale/oauth/key" = fake;
  "crowdsec/enrollKey" = fake;
  "n8n/alertWebhookUrl" = "http://127.0.0.1:65535/fake-webhook";
  "qbit/user" = fake;
  "qbit/password" = fake;

  # --- server/* ---
  "server/hermes/env" = fake;
  "server/honcho/env" = fake;
  "server/n8n/secretKey" = fake;
  "server/gluetun/env" = fake;
  "server/arrs/username" = fake;
  "server/arrs/password" = fake;
  "server/questarr/env" = fake;
  "server/qui/env" = fake;
  "server/immich/env" = fake;
  "server/immich/oidc-client-secret" = fake;
  "server/obsidian-livesync/env" = fake;
  "server/borg/repoPassword" = fake;
  "server/restic/repoPassword" = fake;
  "server/traefik/clientCaCert" = fake;
  "server/forgejo/strange/dbPassword" = fake;
  "server/forgejo/strange/mail" = fake;
  "server/forgejo/strange/password" = fake;
  "server/lldap/admin_password" = fake;
  "server/lldap/env" = fake;
  "server/lldap/jwt_secret" = fake;
  "server/authelia/hmac_secret" = fake;
  "server/authelia/jwt-secret" = fake;
  "server/authelia/ldap/password" = fake;
  "server/authelia/oidc_private_key" = fake;
  "server/authelia/smtp/password" = fake;
  "server/authelia/storage-encryption-key" = fake;
  "server/jellyfin/user/admin/password" = fake;
  "server/jellyfin/user/strange/password" = fake;

  # Vaultwarden mounts this one as /data/config.json, so it must be VALID JSON
  # or the container's config parser rejects it.
  "server/vaultwarden/config" = "{}";
  "server/vaultwarden/env" = fake;
}
