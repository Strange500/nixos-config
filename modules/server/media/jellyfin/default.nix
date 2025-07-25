{
  config,
  pkgs,
  lib,
  ...
}: {
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

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        jellyfin = {
          rule = "Host(`jellyfin.${config.qgroget.server.domain}`)";
          entryPoints = ["websecure"];
          service = "jellyfin";
          tls = {
            certResolver = if config.qgroget.server.test.enable then "staging" else "production";
          };
        };
      };

      services = {
        jellyfin = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8096";}
            ];
          };
        };
      };
    };
  };

  services.declarative-jellyfin = {
    enable = true;
    serverId = "68fb5b2c9433451fa16eb7e29139e7f2";

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
}
