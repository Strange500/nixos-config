{config, ...}: let
  logDir = "${config.qgroget.logDir}/jellyfin";
in {
  imports = [
    ./jellyseer.nix
  ];

  sops = {
    secrets."server/jellyfin/user/admin/password" = {
    };
    secrets."server/jellyfin/user/strange/password" = {
    };
  };

  environment.persistence."/persist".directories = [
    "/var/cache/jellyfin"
    "/var/lib/jellyfin"
  ];

  # system tmp file to give read access to every file inside /var/lib/jellyfin/log
  # systemd.tmpfiles.rules = [
  #   "d /var/lib/jellyfin 0755 jellyfin jellyfin -"
  #   "d /var/lib/jellyfin/log 0755 jellyfin jellyfin -"
  #   "Z /var/lib/jellyfin/log/*.log 0644 jellyfin jellyfin -"
  # ];

  # allow DLNA devices to access Jellyfin
  networking.firewall = {
    allowedUDPPorts = [1900 7359];
    allowedTCPPorts = [8096];
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.enableRedistributableFirmware = true;

  # add user jellyfin to video and render groups
  users.users.jellyfin = {
    extraGroups = ["video" "render"];
  };

  services.declarative-jellyfin = {
    enable = true;
    serverId = "68fb5b2c9433451fa16eb7e29139e7f2";
    backups = false;
    logDir = logDir;
    user = "jellyfin";
    group = "jellyfin";

    network.knownProxies = [
      "127.0.0.1"
    ];

    system = {
      UICulture = "fr-FR";
      activityLogRetentionDays = 30;
      allowClientLogUpload = true;
      serverName = "QGRoget";
      trickplayOptions = {
        enableHwAcceleration = true;
        enableHwEncoding = true;
      };
    };

    encoding = {
      enableHardwareEncoding = false;
      hardwareAccelerationType = "vaapi";
      hardwareDecodingCodecs = [
        "h264"
        "hevc"
        "mpeg2video"
        "vc1"
      ];
      enableTonemapping = true;
      enableThrottling = true;
    };

    libraries = {
      Movies = {
        enabled = true;
        contentType = "movies";
        pathInfos = ["/mnt/media/media/movies"];
        enableTrickplayImageExtraction = true;
        preferredMetadataLanguage = "fr";
        saveTrickplayWithMedia = true;
        typeOptions.Movies = {
          metadataFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
          imageFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
        };
      };
      Anime_Movies = {
        enabled = true;
        contentType = "movies";
        pathInfos = ["/mnt/media/media/anime_movies"];
        enableTrickplayImageExtraction = true;
        preferredMetadataLanguage = "fr";
        saveTrickplayWithMedia = true;
        typeOptions.Movies = {
          metadataFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
          imageFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
        };
      };
      tv = {
        enabled = true;
        contentType = "tvshows";
        pathInfos = ["/mnt/media/media/tv"];
        enableTrickplayImageExtraction = true;
        preferredMetadataLanguage = "fr";
        saveTrickplayWithMedia = true;
        typeOptions.TvShows = {
          metadataFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
          imageFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
        };
      };
      anime = {
        enabled = true;
        contentType = "tvshows";
        pathInfos = ["/mnt/media/media/anime"];
        enableTrickplayImageExtraction = true;
        preferredMetadataLanguage = "fr";
        saveTrickplayWithMedia = true;
        typeOptions.TvShows = {
          metadataFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
          imageFetchers = [
            "The Open Movie Database"
            "TheMovieDb"
          ];
        };
      };
    };

    users = {
      Admin = {
        mutable = false;
        hashedPasswordFile = config.sops.secrets."server/jellyfin/user/admin/password".path;
        permissions = {
          isAdministrator = true;
        };
      };
      Strange = {
        mutable = true;
        hashedPasswordFile = config.sops.secrets."server/jellyfin/user/strange/password".path;
        permissions = {
          isAdministrator = false;
          enableAllFolders = false;
        };
      };
    };
  };

  qgroget.services = {
    jellyfin = {
      name = "jellyfin";
      url = "http://127.0.0.1:8096";
      type = "public";
      #logPath = "${logDir}/log_*";
      journalctl = true;
      unitName = "jellyfin.service";
      middlewares = ["jellyfin-mw"];
    };
  };

  services.traefik.dynamicConfigOptions = {
    http.middlewares.jellyfin-mw = {
      headers = {
        customResponseHeaders = {
          X-Robots-Tag = "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
          X-XSS-Protection = "1";
        };
        SSLRedirect = true;
        SSLHost = "jellyfin.${config.qgroget.server.domain}";
        SSLForceHost = true;
        STSSeconds = 315360000;
        STSIncludeSubdomains = true;
        STSPreload = true;
        forceSTSHeader = true;
        frameDeny = true;
        contentTypeNosniff = true;
        customFrameOptionsValue = "allow-from https://jellyfin.${config.qgroget.server.domain}";
      };
    };
  };
}
