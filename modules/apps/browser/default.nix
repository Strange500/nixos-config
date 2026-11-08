{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
lib.mkMerge [
  (import ./firefox.nix {inherit config lib pkgs inputs;})
]
