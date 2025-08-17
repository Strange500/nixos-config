{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.backups;

  repoPath = "/persist/backup/restic";

  # Emulate modulo: x % y = x - y * (x div y)
  rem = x: y: x - y * (builtins.div x y);

  # Timers: start 02:00, then +5 minutes per backup; wrap hours at 24.
  mkTimer = idx: let
    stepMin = 5;
    startHour = 2;
    total = idx * stepMin; # minutes to add
    addHours = builtins.div total 60; # whole hours to add
    minutes = rem total 60;
    hoursRaw = startHour + addHours;
    hours = rem hoursRaw 24; # keep 0..23
  in {
    # Full systemd calendar spec (daily at HH:MM:SS)
    OnCalendar = "*-*-* ${lib.fixedWidthNumber 2 hours}:${lib.fixedWidthNumber 2 minutes}:00";
    Persistent = true;
  };

  # Build the attrset expected by services.restic.backups
  backups = lib.listToAttrs (lib.imap1
    (idx: elem: let
      name = elem.name;
      backup = elem.value;
    in
      lib.nameValuePair name {
        repository = "${repoPath}/${name}";
        initialize = true;
        passwordFile = config.sops.secrets."server/restic/repoPassword".path;

        # Run restic with cap_dac_read_search wrapper
        user = "restic";
        package = pkgs.writeShellScriptBin "restic" ''
          exec /run/wrappers/bin/restic "$@"
        '';

        paths = backup.paths;
        timerConfig = mkTimer (idx - 1);

        # Hook names as per the NixOS restic module
        backupPrepareCommand = backup.preBackup;
        backupCleanupCommand = backup.postBackup;
      })
    (lib.attrsToList cfg));
in {
  #### Options other modules can populate
  options.qgroget.backups = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        paths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Paths to include in this backup.";
        };
        preBackup = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = "Optional script to run before the backup (backupPrepareCommand).";
        };
        postBackup = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = "Optional script to run after the backup (backupCleanupCommand).";
        };
        systemdUnits = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Systemd units to stop while backup runs.";
        };
      };
    });
    default = {};
    description = "Declarative restic backups keyed by service name.";
  };

  #### Implementation
  config = {
    systemd.tmpfiles.rules = [
      "d ${repoPath} 0755 restic users - -"
    ];

    users.users.restic = {
      isNormalUser = true;
    };

    security.wrappers.restic = {
      source = "${pkgs.restic.out}/bin/restic";
      owner = "restic";
      group = "users";
      permissions = "u=rwx,g=,o=";
      capabilities = "cap_dac_read_search=+ep";
    };

    sops.secrets."server/restic/repoPassword" = {
      mode = "0600";
      owner = "restic";
    };

    services.restic.backups = backups;

    systemd.services = lib.listToAttrs (
      lib.imap1
      (
        idx: elem: let
          name = elem.name;
          backup = elem.value;
        in
          lib.nameValuePair "restic-backups-${name}"
          (lib.mkIf (backup.systemdUnits != []) {
            serviceConfig = {
              ExecStartPre =
                map (u: "+${pkgs.systemd}/bin/systemctl stop ${u}") backup.systemdUnits;
              ExecStartPost =
                map (u: "+${pkgs.systemd}/bin/systemctl start ${u}") backup.systemdUnits;
            };
          })
      )
      (lib.attrsToList cfg)
    );
  };
}
