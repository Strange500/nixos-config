{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
lib.mkMerge [
  (lib.mkIf (config.qgroget.nixos.desktop.loginManager == "ly") (import ./ly/ly.nix {inherit pkgs config inputs lib;}))
  (lib.mkIf (config.qgroget.nixos.desktop.loginManager == "gdm") (import ./gdm/gdm.nix {inherit pkgs config inputs lib;}))
]
