{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = lib.mkIf config.qgroget.nixos.apps.media [
    pkgs.mpv
  ];
}
