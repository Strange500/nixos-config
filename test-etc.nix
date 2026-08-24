{
  config,
  pkgs,
  lib,
  ...
}: {
  environment.etc."traefik/dynamic/inject-basic-arr.toml".source = "/run/traefik/secureConf/inject-basic-arr.toml";
}
