{
  pkgs,
  declarative-jellyfin,
  ...
}:
pkgs.testers.nixosTest {
  name = "jellyfin-test";

  nodes = {
    server = {...}: {
      imports = [
        ../../settings.nix
        ../../modules/server/options.nix
        ../../modules/server/media/video
        declarative-jellyfin.nixosModules.default
      ];

      config = {
        environment.etc."passwordTest".text = "$PBKDF2-SHA512$iterations=210000$03AAF10BC9C336BABAF373C15C75391F$C3B22B0A38EE884514C16C139E584BB7D418CDAD003026251BDB49AC9E07A9FA265E67FDBB919A76E891C77D7A0B9EDD9C754637509D2AB5D9D0F35AED2CC92F";
        virtualisation.diskSize = 4096;

        qgroget.server.jellyfin = {
          enable = true;
          allowDLNA = true;
          mediaPaths = {
            movies = ["/tmp/movies"];
            animeMovies = ["/tmp/anime_movies"];
            tv = ["/tmp/tv"];
            anime = ["/tmp/anime"];
            music = ["/tmp/music"];
          };
          users = {
            admin = {
              mutable = false;
              hashedPasswordSecret = "/etc/passwordTest";
              permissions = {isAdministrator = true;};
            };
            strange = {
              mutable = true;
              hashedPasswordSecret = "/etc/passwordTest";
              permissions = {
                isAdministrator = false;
                enableAllFolders = false;
              };
            };
          };
        };
      };
    };
    client = {...}: {
      config = {};
    };
  };
  testScript = ''
    import time
    start_all()
    server.wait_for_unit("jellyfin.service")
    server.wait_for_open_port(8096)

    # Wait a bit for jellyfin to be fully started
    time.sleep(50)

    # Health check
    server.succeed("curl -f http://localhost:8096/health")
    client.succeed("curl -f http://server:8096/health")

    print("All Jellyfin tests passed!")
  '';
}
