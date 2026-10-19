# Stand-in for sops-nix in nixosTest VMs.
#
# WHY A STUB AND NOT sops-nix + a plain file: sops-install-secrets ALWAYS calls
# sops' decrypt on the configured store file (see
# pkgs/sops-install-secrets/main.go, decryptSecret), and `validateSopsFiles =
# false` does NOT skip that — a plain YAML file dies with "sops metadata not
# found". Mocking with sops-nix therefore requires committing a really
# encrypted file PLUS the age key that opens it, which buys nothing when what
# is under test is a SERVICE booting, not sops itself.
#
# So this module replaces the `sops` option tree with a lookup into real files
# in the Nix store, one per fake secret value:
#
#   config.sops.secrets."server/vaultwarden/config".path
#     -> /nix/store/xxx-test-secret-server-vaultwarden-config
#
# Modules keep declaring `sops.secrets."..."` exactly as in production, so the
# path wiring under test (volume mounts, EnvironmentFile=, config files) is the
# real one. Nothing is decrypted and no key material exists anywhere.
#
# Import it in a test node INSTEAD of `sops-nix.nixosModules.sops`; keep the
# import last so its option declarations land first.
{lib, pkgs, config, ...}:
let
  # name -> fake value (.nix, not YAML: no parser needed).
  fakeValues = import ../../secrets/secrets-test.nix;

  # A store path per secret. Strip what a store name cannot carry, so
  # "server/vaultwarden/config" becomes a valid file name.
  fakeFile = name:
    pkgs.writeText
    "test-secret-${lib.replaceStrings ["/" "."] ["-" "-"] name}"
    fakeValues.${name};

  # Secrets a module declared but secrets/secrets-test.nix does not know about:
  # a loud failure beats handing a service an empty file it then rejects.
  declared = lib.attrNames config.sops.secrets;
  missing = lib.filter (name: !(fakeValues ? ${name})) declared;
in {
  options.sops = lib.mkOption {
    type = lib.types.submodule {
      # Tolerate any other sops option a module may set (gnupg.*, ...) so
      # importing this stub never fails evaluation on an unknown key.
      freeformType = lib.types.anything;

      options.age = lib.mkOption {
        type = lib.types.submodule {freeformType = lib.types.anything;};
        default = {};
        description = "Accepted and ignored: no key material exists in tests.";
      };

      options.defaultSopsFile = lib.mkOption {
        type = lib.types.anything;
        default = null;
        description = "Accepted and ignored: values come from secrets/secrets-test.nix.";
      };

      options.secrets = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          freeformType = lib.types.anything;
          options.path = lib.mkOption {
            type = lib.types.path;
            description = "Path this secret's fake value is written to.";
          };
        });
        default = {};
        # Point every declared secret at its fake file. Modules never set
        # `path` themselves (sops-nix owns it in production), so overriding it
        # unconditionally is what makes `config.sops.secrets.<n>.path` usable.
        apply = attrs: lib.mapAttrs (name: cfg: cfg // {path = fakeFile name;}) attrs;
        description = "sops-nix-compatible secret set backed by fake files.";
      };
    };
    default = {};
  };

  config.assertions = [
    {
      assertion = missing == [];
      message = ''
        tests/lib/sops-mock.nix: no fake value for sops secret(s):
          ${lib.concatStringsSep "\n  " missing}
        Add them to secrets/secrets-test.nix (placeholder values only, never
        real credentials).
      '';
    }
  ];
}
