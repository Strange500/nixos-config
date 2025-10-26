{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
lib.mkMerge [
  (import ./brave.nix {inherit config lib pkgs inputs;})
  (import ./firefox.nix {inherit config lib pkgs inputs;})
]
