{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  traefikLib = import ../../lib/traefik.nix {inherit lib;};

  cfg = config.qgroget.traefikRouter;
  services = config.qgroget.services;

  # Router/services generated from `qgroget.services.<name>` declarations,
  # using the same logic as the server-side module (shared `lib/traefik.nix`).
  generatedHttp = traefikLib.mkDynamicHttp {
    domain = cfg.domain;
    testEnable = cfg.test;
    inherit services;
  };

  # Per-service escape hatch (`traefikDynamicConfig`), folded at the dynamic
  # config root exactly like the server-side `mergedTraefikConfig`.
  generated = lib.foldl' lib.recursiveUpdate {http = generatedHttp;} (
    map (svc: svc.traefikDynamicConfig) (lib.attrValues services)
  );

  # Global raw overrides (custom middlewares, TCP routers, tls options...)
  # merged on top, as a final escape hatch.
  dynamicConf = lib.recursiveUpdate generated cfg.config;

  tomlFormat = pkgs.formats.toml {};
in {
  options.qgroget.services = mkOption {
    type = types.attrsOf (types.submodule ({...}: {
      options = {
        subdomain = mkOption {
          type = types.str;
          default = "";
          description = "Service subdomain. Use empty string for the main domain.";
        };
        url = mkOption {
          type = types.str;
          description = "Backend URL Traefik proxies to (rootless, e.g. 127.0.0.1:<port>).";
        };
        type = mkOption {
          type = types.enum ["private" "public"];
          default = "private";
          description = "'private' = local-network + mTLS; 'public' = internet-facing.";
        };
        middlewares = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Traefik middlewares to apply to the router.";
        };
        traefikDynamicConfig = mkOption {
          type = types.attrs;
          default = {};
          description = "Extra raw Traefik dynamic config for this service.";
        };
      };
    }));
    default = {};
    description = "Declarative rootless services exposed behind the central Traefik proxy.";
  };

  options.qgroget.traefikRouter = {
    enable = mkEnableOption "declarative Traefik routes for this home user";
    domain = mkOption {
      type = types.str;
      default = "qgroget.com";
      description = "Base domain routes are served under (e.g. <subdomain>.qgroget.com).";
    };
    test = mkOption {
      type = types.bool;
      default = false;
      description = "Use the ACME staging cert resolver instead of production.";
    };
    config = mkOption {
      type = types.attrs;
      default = {};
      description = "Raw Traefik dynamic config merged on top of the generated one (escape hatch).";
    };
  };

  config = mkIf cfg.enable {
    home.activation.deployTraefikRouter = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD cp -f ${tomlFormat.generate "traefik-router-${config.home.username}.toml" dynamicConf} /var/lib/traefik/dynamic/${config.home.username}.toml
    '';
  };
}
