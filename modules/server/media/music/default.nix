{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = {
    user = "beets";
    group = "music";
    musicDir = "/mnt/music/media/library";
    inboxDir = "/mnt/music/torrent/nicotine";
    configDir = "/var/lib/beets";
    scanCommand = "import -q ${cfg.inboxDir}";
    extraPackages = [
      pkgs.ffmpeg
      pkgs.chromaprint
      pkgs.inotifyTools
      pkgs.util-linux
    ];
    settings = (pkgs.formats.yaml {}).generate "config.yaml" {
      directory = cfg.musicDir;
      library = "${cfg.configDir}/musiclibrary.db";
      art_filename = "cover.jpg";
      threaded = true;

      plugins = [
        "fetchart"
        "embedart"
        "replaygain"
        "scrub"
        "lastgenre"
        "chroma"
        "web"
      ];

      import = {
        write = true;
        move = true;
        copy = false;
        hardlink = false;
        resume = true;
        incremental = true;
      };

      paths = {
        default = "$albumartist/$original_year - $album%aunique{}/$track - $title";
        singleton = "_Singles/$artist - $title";
        comp = "_Compilations/$album%aunique{} ($original_year)/$track - $artist - $title";
      };

      fetchart = {
        auto = true;
        minwidth = 300;
        maxwidth = 1000;
        quality = 85;
        enforce_ratio = true;
      };

      embedart = {
        auto = true;
      };

      replaygain = {
        auto = true;
      };

      scrub = {
        auto = true;
      };

      lastgenre = {
        auto = true;
        source = "album";
        count = 3;
        canonical = true;
      };
    };
  };
in {
  config = {
    users.groups.music = {
      gid = 971;
    };

    users.users.beets = {
      isSystemUser = true;
      home = cfg.configDir;
      createHome = false;
      group = cfg.group;
      uid = 976;
    };

    # install beets and helper tools
    environment.systemPackages = [pkgs.beets] ++ cfg.extraPackages;

    # ensure configDir exists
    systemd.tmpfiles.rules = ["Z ${cfg.configDir} 0700 ${cfg.user} ${cfg.group} -"];
    environment.persistence."/persist".directories = [
      {
        directory = cfg.configDir;
        user = cfg.user;
        group = cfg.group;
        mode = "0700";
      }
    ];

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
              -c ${cfg.settings} \
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
