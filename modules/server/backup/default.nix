{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.backups;

  repoPath = "/persist/backup/restic";

  # One wrapper package, reused everywhere
  resticWrapperPkg = pkgs.writeShellScriptBin "restic" ''
    exec /run/wrappers/bin/restic "$@"
  '';

  # Deterministic list of backups (sort by priority, then name)
  backupsList = let
    toList = lib.mapAttrsToList (name: value: {inherit name value;}) cfg;
    byPriority = a: b: let
      pa = a.value.priority or 1000;
      pb = b.value.priority or 1000;
    in
      if pa == pb
      then a.name < b.name
      else pa < pb;
  in
    lib.sort byPriority toList;

  # Attrset that services.restic.backups expects
  backupsAttrset = lib.listToAttrs (map
    (elem: let
      name = elem.name;
      backup = elem.value;
    in
      lib.nameValuePair name {
        repository = "${repoPath}/${name}";
        initialize = true;
        user = "restic";
        package = resticWrapperPkg;
        passwordFile = config.sops.secrets."server/restic/repoPassword".path;
        paths = backup.paths;
        exclude = backup.exclude;
        # IMPORTANT: disable per-backup timers; coordinator drives schedule
        timerConfig = lib.mkForce null;
        backupPrepareCommand = backup.preBackup;
        backupCleanupCommand = backup.postBackup;
      })
    backupsList);
in {
  #### Options
  options.qgroget.backups = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        paths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Paths to include in this backup.";
        };
        exclude = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Patterns or paths to exclude (restic --exclude / --exclude-file).";
        };
        preBackup = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = "Script to run before the backup.";
        };
        postBackup = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = "Script to run after the backup.";
        };
        systemdUnits = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Units to stop while this backup runs.";
        };
        priority = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = "Lower runs earlier in the coordinator chain.";
        };
        # Optional: require network for this backup (e.g., remote repos)
        requireNetwork = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "If true, add Wants/After=network-online.target to this backup.";
        };
      };
    });
    default = {};
    description = "Declarative restic backups keyed by service name.";
  };

  config = {
    users.groups.restic = {};
    users.users.restic = {
      isSystemUser = true;
      group = "restic";
    };

    systemd.tmpfiles.rules = [
      "d ${repoPath} 0750 restic restic - -"
    ];

    # Capability wrapper limited to restic group
    security.wrappers.restic = {
      source = "${pkgs.restic.out}/bin/restic";
      owner = "root";
      group = "restic";
      permissions = "0750";
      capabilities = "cap_dac_read_search=+ep";
    };

    sops.secrets."server/restic/repoPassword" = {
      mode = "0600";
      owner = "restic";
      group = "restic";
    };

    services.restic.backups = backupsAttrset;

    systemd.services = lib.mkMerge ([
        {
          # Coordinator runs one-by-one, stopping/starting units.
          restic-backup-coordinator = {
            description = "Restic backup coordinator";
            serviceConfig = {
              Type = "oneshot";
              Nice = 10;
              IOSchedulingClass = "best-effort";
              IOSchedulingPriority = 7;
              ExecStart = pkgs.writeShellScript "backup-coordinator" ''
                set -euo pipefail
                sys=${pkgs.systemd}/bin/systemctl

                run_one() {
                  local name="$1"; shift
                  local units=("$@")

                  echo "==> Starting backup: ''${name}"
                  for u in "''${units[@]}"; do
                    echo "   - stopping $u"
                    "$sys" stop "$u" || true
                  done
                  trap '
                    for u in "''${units[@]}"; do
                      echo "   - starting $u"
                      "$sys" start "$u" || true
                    done
                  ' RETURN

                  if ! "$sys" start --wait "restic-backups-''${name}.service"; then
                    echo "!! Backup ''${name} failed"
                    return 1
                  fi
                  echo "<= Backup ''${name} completed successfully"
                }

                ${lib.concatMapStringsSep "\n" (
                    elem: let
                      escapedName = lib.escapeShellArg elem.name;
                      units = lib.concatMapStringsSep " " (u: lib.escapeShellArg u) elem.value.systemdUnits;
                    in ''
                      run_one ${escapedName} ${units}
                    ''
                  )
                  backupsList}
              '';
            };
          };
          restic-maintenance = {
            description = "Restic prune & check (all repos)";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "restic-maintenance" ''
                set -euo pipefail
                for name in ${lib.concatMapStringsSep " " (e: lib.escapeShellArg e.name) backupsList}; do
                  echo "==> prune $name"
                  ${resticWrapperPkg}/bin/restic -r ${repoPath}/"$name" --password-file ${config.sops.secrets."server/restic/repoPassword".path} forget --prune \
                    --keep-daily 7 --keep-weekly 4 --keep-monthly 12
                  echo "==> check $name"
                  ${resticWrapperPkg}/bin/restic -r ${repoPath}/"$name" --password-file ${config.sops.secrets."server/restic/repoPassword".path} check --read-data-subset=1/10
                done
              '';
              Nice = 10;
              IOSchedulingClass = "best-effort";
              IOSchedulingPriority = 7;
            };
          };
        }
      ]
      # Per-backup network deps
      ++ (map
        (elem: let
          name = elem.name;
          requiresNet = elem.value.requireNetwork or false;
        in {
          "restic-backups-${name}" = {
            wantedBy = lib.mkForce []; # ensure no auto-start
            # If some backups need network (e.g., rclone/rest-server)
            unitConfig = lib.mkIf requiresNet {
              Wants = ["network-online.target"];
              After = ["network-online.target"];
            };
          };
        })
        backupsList));

    # One timer to rule them all
    systemd.timers =
      {
        restic-backup-coordinator = {
          description = "Trigger restic backup chain";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "*-*-* 02:00:00";
            RandomizedDelaySec = "15m";
            Persistent = true;
          };
        };
        restic-maintenance = {
          description = "Weekly restic maintenance";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "Sun 03:30";
            RandomizedDelaySec = "30m";
            Persistent = true;
          };
        };
      }
      // lib.listToAttrs (map
        (elem:
          lib.nameValuePair "restic-backups-${elem.name}" {
            wantedBy = lib.mkForce [];
          })
        backupsList);
  };
}
