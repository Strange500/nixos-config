{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    #../../modules/system/tpm/tpm.nix
    ./disk-config.nix
  ];

  users.mutableUsers = false;

  services.declarative-jellyfin = {
    enable = true;
    serverId = "68fb5b2c9433451fa16eb7e29139e7f2";

    libraries = {
      # Movies = {
      #   enabled = true;
      #   contentType = "movies";
      #   pathInfos = [ "/data/Movies" ];
      #   typeOptions.Movies = {
      #     metadataFetchers = [
      #       "The Open Movie Database"
      #       "TheMovieDb"
      #     ];
      #     imageFetchers = [
      #       "The Open Movie Database"
      #       "TheMovieDb"
      #     ];
      #   };
      # };
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
        password = "123";
        permissions = {
          isAdministrator = true;
        };
      };
      # Alice = {
      #   mutable = false;
      #   hashedPassword = builtins.readFile ../tests/example_hash.txt;
      #   permissions = {
      #     isAdministrator = true;
      #     enableAllFolders = false;
      #   };
      #   preferences = {
      #     # Only allow access to photos and music
      #     enabledLibraries = [
      #       "Photos and Videos"
      #       "Music"
      #     ];
      #   };
      # };
      # Bob = {
      #   mutable = false;
      #   hashedPasswordFile = ../tests/example_hash.txt;
      #   permissions = {
      #     isAdministrator = false;
      #   };
      # };
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

 
  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
