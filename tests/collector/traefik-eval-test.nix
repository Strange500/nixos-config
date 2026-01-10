{
  lib,
  pkgs,
  ...
}: let
  config = lib.evalModules {
    modules = [
      ../../modules/server/options.nix
      ../../modules/server/collector.nix
      {
        qgroget.serviceModules.jellyfin = {
          enable = true;
          domain = "example.com";
          dataDir = "/var/lib/jellyfin";
          backupPaths = [];
          exposed = true;
          subdomain = "jellyfin";
          type = "public";
          port = 8096;
          middleware = [];
        };
        qgroget.serviceModules.authentik = {
          enable = true;
          domain = "example.com";
          dataDir = "/var/lib/authentik";
          backupPaths = [];
          exposed = true;
          subdomain = "auth";
          type = "private";
          port = 9000;
          middleware = [];
        };
        qgroget.serviceModules.internal-service = {
          enable = true;
          domain = "example.com";
          dataDir = "/var/lib/internal";
          backupPaths = [];
          exposed = true;
          subdomain = "internal";
          type = "internal";
          port = 3000;
          middleware = [];
        };
        qgroget.serviceModules.service-with-custom-middleware = {
          enable = true;
          domain = "example.com";
          dataDir = "/var/lib/custom";
          backupPaths = [];
          exposed = true;
          subdomain = "custom";
          type = "private";
          port = 8080;
          middleware = ["rate-limit" "geoblock"];
        };
        qgroget.serviceModules.notExposedService = {
          enable = true;
          domain = "example.com";
          dataDir = "/var/lib/notexposed";
          backupPaths = [];
          exposed = false;
          subdomain = "notexposed";
          type = "private";
          port = 9999;
          middleware = [];
        };
        qgroget.serviceModules.disabledService = {
          enable = false;
          domain = "example.com";
          dataDir = "/var/lib/disabled";
          backupPaths = [];
          exposed = true;
          subdomain = "disabled";
          type = "public";
          port = 7777;
          middleware = [];
        };
      }
    ];
  };

  traefik = config.qgroget.traefik;
  routers = traefik.routers;
  services = traefik.services;

  # Test: Jellyfin (public service)
  jellyfinRouter = routers.jellyfin or throw "jellyfin router not found";
  testJellyfinRule = assert jellyfinRouter.rule == "Host(`jellyfin.example.com`)"; true;
  testJellyfinService = assert jellyfinRouter.service == "service-jellyfin"; true;
  testJellyfinMiddleware = assert jellyfinRouter.middlewares == []; true;
  testJellyfinEntrypoint = assert jellyfinRouter.entryPoints == ["websecure"]; true;

  jellyfinServiceCfg = services.jellyfin or throw "jellyfin service not found";
  testJellyfinUrl = assert jellyfinServiceCfg.loadBalancer.servers == [{url = "http://localhost:8096";}]; true;

  # Test: Authentik (private service with automatic authentik middleware)
  authentikRouter = routers.authentik or throw "authentik router not found";
  testAuthentikRule = assert authentikRouter.rule == "Host(`auth.example.com`)"; true;
  testAuthentikMiddleware = assert authentikRouter.middlewares == ["authentik"]; true;

  # Test: Internal service (no default middleware)
  internalRouter = routers.internal-service or throw "internal-service router not found";
  testInternalMiddleware = assert internalRouter.middlewares == []; true;

  # Test: Service with custom middleware (combines type default + custom)
  customRouter = routers.service-with-custom-middleware or throw "service-with-custom-middleware router not found";
  testCustomMiddleware = assert customRouter.middlewares == ["authentik" "rate-limit" "geoblock"]; true;

  # Test: Not exposed service should not have router
  testNotExposed = assert !(routers ? notExposedService); true;

  # Test: Disabled service should not have router
  testDisabled = assert !(routers ? disabledService); true;

  # Test: Router counts
  testRouterCount = assert (lib.length (lib.attrNames routers)) == 4; true;
  testServiceCount = assert (lib.length (lib.attrNames services)) == 4; true;
in
  pkgs.runCommand "traefik-routing-test" {} "echo 'test passed' > $out"
