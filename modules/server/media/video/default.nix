{config, ...}: {
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

  qgroget.backups.jellyfin = {
    paths = [
      "${config.services.jellyfin.dataDir}"
    ];
    systemdUnits = [
      "jellyfin.service"
    ];
  };

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
      enableHardwareEncoding = true;
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
      journalctl = true;
      unitName = "jellyfin.service";
      middlewares = ["jellyfin-mw"];
    };
  };

  qgroget.services.jellyfin.traefikDynamicConfig = {
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
