{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  options = {
    login.ly.enable = lib.mkEnableOption "ly";
  };

  config = lib.mkMerge [
    (lib.mkIf config.login.ly.enable (import ./ly/ly.nix {inherit pkgs config inputs lib;}))
  ];
}
