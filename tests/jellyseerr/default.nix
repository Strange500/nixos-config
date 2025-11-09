{pkgs, ...}:
pkgs.testers.nixosTest {
  name = "jellyseer-test";

  nodes = {
    server = {...}: {
      imports = [
        ../../settings.nix
        ../../modules/server/options.nix
        ../../modules/server/media/video/jellyseer.nix
      ];

      config = {
        qgroget.server.jellyseerr = {
          enable = true;
          port = 5055;
        };
      };
    };
    client = {...}: {
      config = {};
    };
  };
  testScript = ''
    start_all()

    server.wait_for_unit("jellyseerr.service")
    server.wait_for_open_port(5055)

    # Health check
    server.succeed("curl -f http://localhost:5055/api/v1/status")
    # check that client cannot access jellyseerr
    client.fail("curl -f http://server:5055/api/v1/status")
    # ping from client to server
    client.succeed("ping -c 3 server")
  '';
}
