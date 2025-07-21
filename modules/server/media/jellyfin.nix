{
  config,
  pkgs,
  ...
}: {
  sops = {
    secrets."server/jellyfin/user/admin/password" = {
    };
    secrets."server/jellyfin/user/strange/password" = {
    };
  };

  services.declarative-jellyfin = {
    enable = true;
    serverId = "68fb5b2c9433451fa16eb7e29139e7f2";

    libraries = {
      Movies = {
        enabled = true;
        contentType = "movies";
        pathInfos = [ "/mnt/media/media/movies" ];
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
      # Shows = {
      #   enabled = true;
      #   contentType = "tvshows";
      #   pathInfos = [ "/data/Shows" ];
      # };
      # "Photos and videos" = {
      #   enabled = true;
      #   contentType = "homevideos";
      #   pathInfos = [
      #     "/data/Pictures"
      #     "/data/Videos"
      #   ];
      # };
      # Books = {
      #   enabled = true;
      #   contentType = "books";
      #   pathInfos = [ "/data/Books" ];
      # };
      # Music = {
      #   enabled = true;
      #   contentType = "music";
      #   pathInfos = [ "/data/Music" ];
      # };
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
        preferences = {
          # Only allow access to photos and music
          # enabledLibraries = [
          #   "Photos and Videos"
          #   "Music"
          # ];
        };
      };
    };

    apikeys = {
      Jellyseerr = {
        key = "78878bf9fc654ff78ae332c63de5aeb6";
      };
      # Homarr = {
      #   keyPath = ../tests/example_apikey.txt;
      # };
    };
    openFirewall = true;

    # TODO: add more
  };
}
