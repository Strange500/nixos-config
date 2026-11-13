# Uses only the two relevant inputs, at exactly the flake.lock revisions.
let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  source = name: builtins.fetchTree lock.nodes.${lock.nodes.${lock.root}.inputs.${name}}.locked;
  pkgs = import (source "nixpkgs").outPath {};
  home-manager.lib = import ((source "home-manager").outPath + "/lib") {inherit (pkgs) lib;};
in
  import ./opencode-remote.nix {inherit pkgs home-manager;}
