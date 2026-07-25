{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.qgroget.server.calibre-importer;
  importScript = pkgs.writeShellScriptBin "calibre-import" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.findutils}/bin:${pkgs.calibre}/bin:$PATH"

    SOURCE_DIR="${cfg.sourceDir}"
    LIB_DIR="${cfg.libraryDir}"
    STATE_FILE="${cfg.stateDir}/processed.txt"

    mkdir -p "$LIB_DIR"
    mkdir -p "${cfg.stateDir}"
    touch "$STATE_FILE"

    # Find all supported ebook files and process them
    find "$SOURCE_DIR" -type f \( -iname "*.epub" -o -iname "*.pdf" -o -iname "*.mobi" -o -iname "*.azw3" -o -iname "*.cbz" -o -iname "*.cbr" \) | while read -r file; do
        if ! grep -Fxq "$file" "$STATE_FILE"; then
            echo "Importing: $file"

            FILENAME=$(basename "$file")
            FILENAME_NOEXT="''${FILENAME%.*}"
            PARENT_DIR=$(basename "$(dirname "$file")")

            # Setup the base command
            CMD=(calibredb add --with-library="$LIB_DIR" "$file")

            # CBZ and CBR files rarely contain embedded metadata.
            # To prevent Calibre from dumping them into "Inconnu(e)",
            # we force the Author to be the Parent Directory (e.g. "Mushoku Tensei")
            # and the Title to be the filename.
            if [[ "$file" == *.cbz ]] || [[ "$file" == *.cbr ]] || [[ "$file" == *.CBZ ]] || [[ "$file" == *.CBR ]]; then
                CMD+=(--authors="$PARENT_DIR" --title="$FILENAME_NOEXT")
            fi

            if "''${CMD[@]}"; then
                echo "$file" >> "$STATE_FILE"
                echo "Successfully imported $file"
            else
                echo "Failed to import: $file"
            fi
        fi
    done
  '';
in {
  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Calibre auto-importer user";
    };
    users.groups.${cfg.group} = {};

    # Ensure state directory is created with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.libraryDir} 0775 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.calibre-importer = {
      description = "Headless Calibre Auto-Importer";
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${importScript}/bin/calibre-import";
        # Basic hardening
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        ReadWritePaths = [cfg.stateDir cfg.libraryDir];
        ReadOnlyPaths = [cfg.sourceDir];
        Environment = ["CALIBRE_CONFIG_DIRECTORY=${cfg.stateDir}/.config" "HOME=${cfg.stateDir}"];
      };
    };

    systemd.timers.calibre-importer = {
      description = "Timer for Headless Calibre Auto-Importer";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
      };
    };
  };
}
