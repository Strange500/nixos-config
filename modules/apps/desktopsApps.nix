{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  options = {
    desktopsApps = lib.mkOption {
      type = lib.types.submodule {
        options = {
          firefox.enable = lib.mkEnableOption "Firefox";
          kitty.enable = lib.mkEnableOption "Kitty terminal";
          syncthing.enable = lib.mkEnableOption "Syncthing";
        };
      };
      default = {};
      description = "Desktop applications options";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.desktopsApps.firefox.enable (import ./firefox/firefox.nix {inherit config inputs pkgs lib;}))
    (lib.mkIf config.desktopsApps.kitty.enable (import ./kitty/kitty.nix {inherit config inputs lib pkgs;}))
    (lib.mkIf config.desktopsApps.syncthing.enable (import ./syncthing/syncthing.nix {inherit config inputs pkgs lib;}))
    (import ./oh-my-zsh/oh-my-zsh.nix {inherit config inputs pkgs lib;})
  ];
}
