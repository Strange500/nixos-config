{config, lib, ...}: {
  sops = {
    # Early activation runs before non-initrd filesystems such as /persist are
    # mounted. The upstream unit orders decryption after local-fs.target and
    # derives RequiresMountsFor from age.keyFile (also safe without /persist).
    useSystemdActivation = true;
    age.keyFile = "${config.qgroget.secretAgeKeyPath}";
    defaultSopsFile = ../../secrets/secrets.yaml;

    secrets = {
      # Issue #64: these were previously materialized by the primary user's
      # home-manager sops, which forced the age MASTER key (secretAgeKeyPath) to be
      # world-readable (0644). They are now SYSTEM secrets: the master key is only
      # ever read by root (via the sops-nix service). mode 0400 + owner = primary
      # user lets exactly the two legitimate readers through — the primary user
      # (GH_TOKEN session var + .ssh/config IdentityFile in home.nix) and root
      # (hermes.service ExecStartPre, borg BORG_RSH — root bypasses permissions).
      "github_token" = {
        mode = "0400";
        owner = "${config.qgroget.user.username}";
      };
      "git/ssh/private" = {
        mode = "0400";
        owner = "${config.qgroget.user.username}";
      };
      # Firefox client certificate (desktops only). Previously declared in the
      # home-manager scope (home.nix -> desktopsApps), which kept the user-level
      # sops module alive and tied to the age master key. Now a system secret:
      # root materializes it, the primary user reads it.
      "firefox/certFilePKCS12.p12" = lib.mkIf config.qgroget.nixos.apps.basic {
        format = "binary";
        sopsFile = ../../secrets/client.p12;
        mode = "0400";
        owner = "${config.qgroget.user.username}";
      };
    };
  };

  # Issue #64 guard-rail: the age master key must never be readable by a local
  # user again. Home Manager no longer consumes it, so enforce root-only perms at
  # every boot. `z` only adjusts an existing file and is a no-op on hosts without
  # it, so this is safe on every host.
  systemd.tmpfiles.rules = [
    "z ${config.sops.age.keyFile} 0400 root root -"
  ];
}
