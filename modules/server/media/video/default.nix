{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.server.jellyfin;
  commonFetchers = {
    metadata = ["The Open Movie Database" "TheMovieDb"];
    images = ["The Open Movie Database" "TheMovieDb"];
  };
in {
  options.qgroget.server.jellyfin = {
    enable = lib.mkEnableOption "Custom Jellyfin setup with declarative config";
    user = lib.mkOption {
      type = lib.types.str;
      default = "jellyfin";
      description = "The system user that runs Jellyfin.";
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "jellyfin";
      description = "The system group that runs Jellyfin.";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8096;
      description = "The port Jellyfin listens on.";
    };
    knownProxies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["127.0.0.1"];
      description = "List of known proxy IP addresses.";
    };
    serverId = lib.mkOption {
      type = lib.types.str;
      default = "68fb5b2c9433451fa16eb7e29139e7f2";
      description = "Jellyfin server ID.";
    };
    serverName = lib.mkOption {
      type = lib.types.str;
      default = "QGRoget";
      description = "Jellyfin server name.";
    };
    mediaPaths = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        movies = ["/mnt/data/media/media/movies"];
        animeMovies = ["/mnt/data/media/media/anime_movies"];
        tv = ["/mnt/data/media/media/tv"];
        anime = ["/mnt/data/media/media/anime"];
        music = ["/mnt/data/media/media/music/library"];
      };
      description = "Paths for media libraries.";
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          mutable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          hashedPasswordSecret = lib.mkOption {type = lib.types.str;};
          permissions = lib.mkOption {
            type = lib.types.attrs;
            default = {};
          };
        };
      });
      default = {
        admin = {
          mutable = false;
          hashedPasswordSecret = "server/jellyfin/user/admin/password";
          permissions = {isAdministrator = true;};
        };
        # strange = {
        #   mutable = true;
        #   hashedPasswordSecret = "server/jellyfin/user/strange/password";
        #   permissions = {
        #     isAdministrator = false;
        #     enableAllFolders = false;
        #   };
        # };
      };
    };
    allowDLNA = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DLNA support in Jellyfin.";
    };
    enableBackups = lib.mkEnableOption "Enable backups for Jellyfin data";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.allowDLNA {
      allowedUDPPorts = [1900 7359];
      allowedTCPPorts = [8096];
    };

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
    hardware.enableRedistributableFirmware = true;

    qgroget.services.jellyfin = {
      name = "jellyfin";
      url = "http://127.0.0.1:8096";
      type = "public";
      journalctl = true;
      unitName = "jellyfin.service";
      middlewares = ["jellyfin-mw"];
      persistedData = [
        "/var/cache/jellyfin"
        "/var/lib/jellyfin"
      ];
      # backupDirectories = [
      #   "/var/lib/jellyfin"
      # ];
    };

    qgroget.backups.jellyfin = {
      paths = [
        "/var/lib/jellyfin"
      ];
      systemdUnits = [
        "jellyfin.service"
      ];
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

    # add user jellyfin to video and render groups
    users.users.${cfg.user} = {
      extraGroups = ["video" "render" "media" "music"];
    };

    services.declarative-jellyfin = {
      enable = true;
      serverId = cfg.serverId;
      backups = cfg.enableBackups;
      user = cfg.user;
      group = cfg.group;

      users =
        lib.mapAttrs (name: user: {
          mutable = user.mutable;
          hashedPasswordFile = user.hashedPasswordSecret;
          permissions = user.permissions;
        })
        cfg.users;

      network.knownProxies = cfg.knownProxies;

      system = {
        UICulture = "fr-FR";
        activityLogRetentionDays = 30;
        allowClientLogUpload = true;
        serverName = cfg.serverName;
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
          pathInfos = cfg.mediaPaths.movies;
          enableTrickplayImageExtraction = false;
          preferredMetadataLanguage = "fr";
          saveTrickplayWithMedia = true;
          typeOptions.Movies = {
            metadataFetchers = commonFetchers.metadata;
            imageFetchers = commonFetchers.images;
          };
        };
        Anime_Movies = {
          enabled = true;
          contentType = "movies";
          pathInfos = cfg.mediaPaths.animeMovies;
          enableTrickplayImageExtraction = false;
          preferredMetadataLanguage = "fr";
          saveTrickplayWithMedia = true;
          typeOptions.Movies = {
            metadataFetchers = commonFetchers.metadata;
            imageFetchers = commonFetchers.images;
          };
        };
        tv = {
          enabled = true;
          contentType = "tvshows";
          pathInfos = cfg.mediaPaths.tv;
          enableTrickplayImageExtraction = false;
          preferredMetadataLanguage = "fr";
          saveTrickplayWithMedia = true;
          typeOptions.TvShows = {
            metadataFetchers = commonFetchers.metadata;
            imageFetchers = commonFetchers.images;
          };
        };
        anime = {
          enabled = true;
          contentType = "tvshows";
          pathInfos = cfg.mediaPaths.anime;
          enableTrickplayImageExtraction = false;
          preferredMetadataLanguage = "fr";
          saveTrickplayWithMedia = true;
          typeOptions.TvShows = {
            metadataFetchers = commonFetchers.metadata;
            imageFetchers = commonFetchers.images;
          };
        };
        music = {
          enabled = true;
          contentType = "music";
          pathInfos = cfg.mediaPaths.music;
        };
      };
    };
  };
}
