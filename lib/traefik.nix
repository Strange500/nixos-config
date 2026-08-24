{
  lib,
}: let
  # Shared Traefik dynamic-config generation, used by BOTH the server-side
  # module (`modules/server/traefik/default.nix`) and the Home Manager
  # `qgroget.traefikRouter` module, so a rootless user declares a service the
  # same way the server does (`qgroget.services.<name>`), with identical
  # routing rules (Host matcher, mTLS, cert resolver, googlenoindex).
  generateRouter = {
    domain,
    testEnable,
    name,
    service,
  }: let
    baseMiddlewares =
      if builtins.hasAttr "middlewares" service
      then service.middlewares
      else [];
    finalMiddlewares = baseMiddlewares ++ lib.optional (name != "portfolio") "googlenoindex";
  in
    {
      rule = "Host(`${
        if service.subdomain != ""
        then service.subdomain + "."
        else ""
      }${domain}`)";
      entryPoints = ["websecure"];
      service = name;
      tls =
        {
          certResolver =
            if testEnable
            then "staging"
            else "production";
        }
        // lib.optionalAttrs (service.type == "private") {
          options = "mtls";
        };
    }
    // lib.optionalAttrs (finalMiddlewares != []) {
      middlewares = finalMiddlewares;
    };

  generateService = name: service: {
    loadBalancer = {
      servers = [
        {url = service.url;}
      ];
    };
  };

  # Build the Traefik `http` dynamic config (routers + services + the shared
  # `googlenoindex` middleware) for a set of declared services.
  mkDynamicHttp = {
    domain,
    testEnable,
    services,
  }: {
    routers = lib.mapAttrs (name: service: generateRouter {inherit domain testEnable name service;}) services;
    services = lib.mapAttrs generateService services;
    middlewares = {
      googlenoindex = {
        headers = {
          customResponseHeaders = {
            X-Robots-Tag = "noindex";
          };
        };
      };
    };
  };
in {
  inherit generateRouter generateService mkDynamicHttp;
}