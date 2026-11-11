{
  pkgs,
  nixpkgs,
  sops-nix,
}: let
  inherit (pkgs) lib;
  # Use the real pinned sops-nix module: the service name, boot ordering and
  # RequiresMountsFor are upstream behavior, not a mock of our desired result.
  mkConfig = keyFile: withPersist:
    (nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        sops-nix.nixosModules.sops
        ../../modules/system/sops.nix
        ({lib, ...}: {
          options.qgroget = {
            secretAgeKeyPath = lib.mkOption {type = lib.types.str;};
            user.username = lib.mkOption {type = lib.types.str;};
            nixos.apps.basic = lib.mkOption {type = lib.types.bool;};
          };
          config = {
            qgroget = {
              secretAgeKeyPath = keyFile;
              user.username = "alice";
              nixos.apps.basic = false;
            };
            users.users.alice.isNormalUser = true;
            fileSystems = lib.optionalAttrs withPersist {
              "/persist" = {
                device = "/dev/disk/by-label/persist";
                fsType = "ext4";
                neededForBoot = false;
              };
            };
            system.stateVersion = "24.11";
          };
        })
      ];
    }).config;
  configs = [
    (mkConfig "/persist/var/lib/sops/age/keys.txt" true)
    # A /persist path can live on the root filesystem, e.g. on pi. Do not
    # synthesize a persist.mount dependency when no such mount exists.
    (mkConfig "/persist/var/lib/sops/age/keys.txt" false)
    (mkConfig "/var/lib/sops/age/keys.txt" false)
  ];
  valid = config: let
    unit = config.systemd.services.sops-install-secrets;
    keyFile = config.sops.age.keyFile;
  in
    lib.assertMsg config.sops.useSystemdActivation "SOPS must run after local filesystems, not in early activation"
    && lib.assertMsg (!(config.system.activationScripts ? setupSecrets)) "early SOPS activation must be disabled"
    && lib.elem "local-fs.target" unit.after
    && lib.elem "sysinit.target" unit.before
    && lib.elem "sysinit.target" unit.wantedBy
    && lib.elem "sysinit-reactivation.target" unit.requiredBy
    && lib.elem keyFile unit.unitConfig.RequiresMountsFor
    && !(lib.elem "persist.mount" unit.requires)
    && lib.elem "z ${keyFile} 0400 root root -" config.systemd.tmpfiles.rules
    && config.sops.secrets."git/ssh/private".path == "/run/secrets/git/ssh/private"
    && config.sops.secrets."git/ssh/private".owner == "alice"
    && config.sops.secrets."git/ssh/private".mode == "0400";
in
  assert lib.all valid configs;
    pkgs.runCommand "sops-activation-test" {} ''
      touch "$out"
    ''
