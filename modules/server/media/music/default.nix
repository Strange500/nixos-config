{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.services.beets;
in {
  options.services.beets = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "beets";
      description = "System user to run the beets services.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "music";
      description = "Group for the beets user (should have access to your music tree).";
    };

    musicDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/music/media/library";
      description = "Root path of the organized music library (where beets writes files).";
    };

    inboxDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/music/torrent/nicotine";
      description = "Optional incoming/inbox folder to watch and import from (used when watcher=\"inbox\").";
    };

    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/beets";
      description = "Directory containing config.yaml and beets state. This module sets BEETSDIR for the services.";
    };

    scanCommand = lib.mkOption {
      type = lib.types.str;
      default = "import -q ${toString config.services.beets.inboxDir}";
      description = "The beet subcommand to run when a scan is triggered (e.g. 'update -q' or 'import -q /srv/music_inbox').";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.ffmpeg
        pkgs.chromaprint
        pkgs.inotifyTools
        pkgs.util-linux
      ];
      description = "Extra native packages available to beets and used by plugins (fpcalc/chromaprint, ffmpeg, inotifywait, flock, etc.).";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "If set, the exact YAML text to write to ${config.services.beets.configDir}/config.yaml. If null, the module generates a sane default.";
    };
  };

  config = {
    # create user/group
    users.groups."${cfg.group}" = {};

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.configDir;
      createHome = true;
      uid = 976;
    };

    # install beets and helper tools
    environment.systemPackages = [pkgs.beets] ++ cfg.extraPackages;

    # place the generated config (or user-provided config)
    environment.etc."beets/config.yaml" = {
      text =
        if cfg.configFile != null
        then cfg.configFile
        else ''
          directory: ${cfg.musicDir}
          library: ${cfg.configDir}/musiclibrary.db
          art_filename: cover.jpg
          threaded: yes

          plugins:
            - fetchart
            - embedart
            - replaygain
            - scrub
            - lastgenre
            - chroma
            - web

          import:
            write: yes
            move: yes
            copy: no
            hardlink: no
            resume: yes
            incremental: yes

          paths:
            default: $albumartist/$original_year - $album%aunique{}/$track - $title
            singleton: _Singles/$artist - $title
            comp: _Compilations/$album%aunique{} ($original_year)/$track - $artist - $title

          fetchart:
            auto: yes
            minwidth: 300
            maxwidth: 1000
            quality: 85
            enforce_ratio: yes

          embedart:
            auto: yes

          replaygain:
            auto: yes

          scrub:
            auto: yes

          lastgenre:
            auto: yes
            source: album
            count: 3
            canonical: yes
        '';
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # ensure configDir exists
    systemd.tmpfiles.rules = ["d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"];

    # oneshot scan service (locked via flock)
    systemd.services."beets-scan" = {
      description = "Beets library scan/update";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.musicDir;
        Environment = ["BEETSDIR=${toString cfg.configDir}"];
        RuntimeDirectory = "beets";
        ExecStart = ''
          ${pkgs.util-linux}/bin/flock -n /run/beets/scan.lock \
            ${pkgs.beets}/bin/beet \
              -c /etc/beets/config.yaml \
              -l ${cfg.configDir}/musiclibrary.db \
              -d ${cfg.musicDir} \
              ${cfg.scanCommand}
        '';
      };
    };

    systemd.services."beets-watcher" = {
      description = "Recursive watcher that triggers Beets scans when music files change";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        #User = cfg.user;
        #Group = cfg.group;
        Restart = "always";
        RestartSec = 2;
        Environment = ["MUSIC_DIR=${toString cfg.inboxDir}"];
        ExecStart = ''
          ${pkgs.bash}/bin/bash -eu -o pipefail -c '${pkgs.inotifyTools}/bin/inotifywait -m -r -e close_write,move,create,delete "$MUSIC_DIR" | while read -r; do sleep 2; systemctl start beets-scan.service || true; done'
        '';
      };
    };
  };
}
