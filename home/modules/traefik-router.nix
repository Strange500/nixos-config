{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.qgroget.traefikRouter;
  tomlFormat = pkgs.formats.toml {};
in {
  options.qgroget.traefikRouter = {
    enable = lib.mkEnableOption ''
      declarative Traefik routes for this home user. The declared config is
      serialized to TOML and written to
      `/var/lib/traefik/dynamic/<username>.toml`, which the central Traefik
      instance hot-reloads through its `users` file provider.
    '';

    config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Free-form Traefik dynamic configuration (routers, services, middlewares)
        used to expose this user's rootless services behind the central reverse
        proxy. Traefik only sees the resulting `url` in
        `loadBalancer.servers[]`, so this works identically for a rootless
        podman container and a `systemd --user` unit.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file."/var/lib/traefik/dynamic/${config.home.username}.toml" = {
      source = tomlFormat.generate "traefik-router-${config.home.username}.toml" cfg.config;
      force = true;
    };
  };
}
