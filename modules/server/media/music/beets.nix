{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.services.beets;
  # Build a dedicated Python env so Beets can import optional deps (lastgenre, web, chroma, etc.).
  # beetsEnv = pkgs.python3.withPackages (ps: ([
  #   #ps.beets           # the beets CLI + built-in plugins
  #   ps.pylast          # lastgenre -> Last.fm
  #   ps.pillow          # fetchart/embeddings that manipulate images
  #   ps.requests        # network fetches
  #   ps.flask           # beets 'web' plugin
  #   ps.pyacoustid      # chroma plugin
  # ] ++ (cfg.extraPythonPackages ps)));
in {
  ###### Options
  options.services.beets = {
    enable = lib.mkEnableOption "Beets music library manager with auto-scan";

    user = lib.mkOption {
      type = lib.types.str;
      default = "beets";
      description = "System user that runs Beets.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "jellyfin";
      description = "Primary group for the Beets user (grants access to the music dir).";
    };

    musicDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/music/media/library";
      description = "Root of your organized music library (what Jellyfin scans).";
    };

    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/beets";
      description = "Where Beets stores its state (library.blb, logs, etc.).";
    };

    watcher = lib.mkOption {
      type = lib.types.enum ["inotify" "path" "none"];
      default = "inotify";
      description = ''
        How to trigger scans on changes:
        - "inotify": recursive watcher using inotifywait (best for deep trees)
        - "path":    systemd.path unit (non-recursive; only top-level changes)
        - "none":    do not set up any watcher
      '';
    };

    scanCommand = lib.mkOption {
      type = lib.types.str;
      default = "import -q /mnt/music/torrent/nicotine";
      description = "What 'beet' subcommand to run when changes are detected (e.g., 'update -q', 'write -q', or a custom script).";
    };

    web = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run 'beet web' as a service (simple JSON API/UI).";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8337;
        description = "Port for the Beets web plugin.";
      };
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Listen address for Beets web plugin.";
      };
    };

    # Provide your own extra Python packages if you enable more plugins.
    extraPythonPackages = lib.mkOption {
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      default = ps: [];
      description = "Function receiving the python package set -> list of extra python packages included in the Beets env.";
    };

    # Extra native tools Beets or plugins might call.
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [pkgs.ffmpeg pkgs.bs1770gain pkgs.chromaprint pkgs.inotifyTools pkgs.util-linux pkgs.bash pkgs.coreutils];
      description = "Extra executables available for Beets commands (ffmpeg, bs1770gain, fpcalc, inotifywait, etc.).";
    };

    # Beets configuration file content. A sane default tailored for Jellyfin.
    configText = lib.mkOption {
      type = lib.types.lines;
      default = ''
        directory: ${cfg.musicDir}
        library: ${cfg.configDir}/musiclibrary.blb
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
          resume: yes
          incremental: yes
          quiet_fallback: skip

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
      description = "Contents of /etc/beets/config.yaml.";
    };
  };

  ###### Implementation
  config = {
    environment.systemPackages = [pkgs.beets];

    # System user & group
    users.groups = {
      ${cfg.group} = lib.mkDefault {}; # create group if absent
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.configDir;
      createHome = true;
    };

    # Ensure dirs exist with safe perms
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"
      # Do not forcibly own the musicDir; just ensure it exists if you want.
      # "d ${cfg.musicDir} 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Make the Python env and useful tools available
    # environment.systemPackages = [beetsEnv] ++ cfg.extraPackages;

    # Beets config installed into /etc with correct ownership
    environment.etc."beets/config.yaml" = {
      text = cfg.configText;
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # One-shot job that (de)duplicates runs using a lock
    systemd.services."beets-scan" = {
      description = "Beets library scan/update";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.musicDir;
        # Prevent concurrent scans; flock requires util-linux
        ExecStart = ''
          ${pkgs.util-linux}/bin/flock -n /run/beets-scan.lock \
            ${pkgs.beets}/bin/beet -c /etc/beets/config.yaml ${cfg.scanCommand}
        '';
      };
    };

    # Option A: recursive watcher via inotifywait (default)
    systemd.services."beets-watcher" = lib.mkIf (cfg.watcher == "inotify") {
      description = "Recursive watcher to trigger Beets scans on library changes";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = 2;
        Environment = [
          #"MUSIC_DIR=${cfg.musicDir}" now /mnt/music/torrent/nicotine
          "MUSIC_DIR=/mnt/music/torrent/nicotine"
          "SYSTEMCTL=${pkgs.systemd}/bin/systemctl"
        ];
        ExecStart = ''
          ${pkgs.bash}/bin/bash -eu -o pipefail -c '
            ${pkgs.inotifyTools}/bin/inotifywait -m -r \
              -e close_write,move,create,delete "$MUSIC_DIR" \
            | while read -r _; do
                # naive debounce: allow a brief quiet period before firing
                sleep 2
                $SYSTEMCTL start beets-scan.service || true
              done'
        '';
      };
    };

    # Option B: light-weight systemd.path (non-recursive)
    # systemd.paths."beets-scan" = lib.mkIf (cfg.watcher == "path") {
    #   description = "Trigger Beets scan when ${cfg.musicDir} changes (top-level only)";
    #   wantedBy = [ "multi-user.target" ];
    #   pathConfig = {
    #     PathChanged = [ cfg.musicDir ];
    #     PathModified = [ cfg.musicDir ];
    #   };
    # };

    # Optional beets web API/UI
    # systemd.services."beets-web" = lib.mkIf cfg.web.enable {
    #   description = "Beets web plugin service";
    #   after = [ "network-online.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     Type = "simple";
    #     User = cfg.user;
    #     Group = cfg.group;
    #     ExecStart = ''
    #       ${beetsEnv}/bin/beet -c /etc/beets/config.yaml web \
    #         -p ${toString cfg.web.port} -h ${cfg.web.listenAddress}
    #     '';
    #     Restart = "on-failure";
    #   };
    # };
  };
}
