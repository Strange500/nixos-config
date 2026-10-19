# Mock sops-nix for nixosTest VMs: no real age key, no real secrets.
#
# Import this module in a test node alongside the service module you want to
# exercise. It feeds sops-nix a PLAIN-YAML fake secret file
# (../../secrets/secrets-test.yaml) and disables sops validation + the age key,
# so `config.sops.secrets."...".path` resolves to real files on disk in the VM
# without ever decrypting production credentials.
#
# The test node MUST also import the sops module BEFORE this one, otherwise
# the `sops.*` options don't exist yet:
#   imports = [ sops-nix.nixosModules.sops ../lib/sops-mock.nix ];
#
# Keep secrets/secrets-test.yaml's top-level key tree in lockstep with the real
# secrets.yaml: any new `sops.secrets."..."` referenced by a module MUST also
# exist there or that service's test fails to decrypt (loud failure, not silent).
{...}: {
  sops = {
    # Accept unencrypted YAML/JSON as the secret store (no sops MAC check).
    validateSopsFiles = false;
    # Redirect the secret store to the fake one.
    defaultSopsFile = ../../secrets/secrets-test.yaml;
    # No real key: generate an ephemeral throwaway age key at activation.
    age = {
      keyFile = null;
      generateKey = true;
    };
  };
}