{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf (lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "hyprland") (lib.mkMerge [
      (import ./hyprland/hyprland.nix {inherit config inputs pkgs lib;})
      (import ./hyprland/addons/hypridle/config.nix {inherit config inputs pkgs lib;})
      (import ./hyprland/addons/hyprpanel/config.nix {inherit config inputs pkgs lib;})
      (import ./hyprland/addons/hyprlock/config.nix {inherit config inputs pkgs lib;})
    ]))
  ];
}
