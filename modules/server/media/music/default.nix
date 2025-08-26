{config, ...}: let
  musicDir = "/mnt/music/media/beets"; # Adjust to your music directory
in {
  imports = [
    ./beets.nix
  ];
  qgroget.services.navidrome = {
    name = "navidrome";
    url = "http://127.0.0.1:4533";
    type = "public";
    journalctl = true;
    unitName = "navidrome.service";
  };

  qgroget.backups.navidrome = {
    paths = [
      "${config.qgroget.server.containerDir}/navidrome"
    ];
    systemdUnits = [
      "navidrome.service"
    ];
  };
  environment.etc."tmpfiles.d/navidrome.conf".text = ''
    Z ${config.qgroget.server.containerDir}/navidrome 0700 navidrome music -
  '';
  users.users.navidrome = {
    isSystemUser = true;
    description = "User for running navidrome";
    home = "/nonexistent";
    createHome = false;
    group = "music";
  };
  users.groups.music = {};

  virtualisation.quadlet = {
    containers.navidrome = {
      autoStart = true;

      containerConfig = {
        image = "docker.io/deluan/navidrome:latest";
        user = "${toString config.users.users.navidrome.uid}:${toString config.users.groups.music.gid}";

        # Environment variables
        environments = {
          ND_SCANSCHEDULE = "@every 12h";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
          ND_BASEURL = "";
        };

        # Volume mounts
        volumes = [
          "${config.qgroget.server.containerDir}/navidrome/data:/data:Z"
          "${musicDir}:/music:ro,Z"
        ];

        # Port mapping
        publishPorts = ["4533:4533"];
      };

      serviceConfig = {
        Restart = "unless-stopped";
      };

      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };
  };
}
