{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  options = {
    desktop = {
      hyprDesktop = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "Enable Hyprland desktop environment";
            settings = lib.mkOption {
              type = lib.types.attrsOf (lib.types.listOf lib.types.str);
              description = "Hyprland settings as an attribute set of lists of strings.";
            };
          };
        };
        default = {
          enable = true;
          settings = {
            monitor = [", preferred, auto, 1"];
          };
        };
        description = "Hyprland desktop environment configuration.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.desktop.hyprDesktop.enable (lib.mkMerge [
      (import ./hyprland/hyprland.nix {inherit config inputs pkgs lib;})
      (import ./hyprland/addons/hypridle/config.nix {inherit config inputs pkgs lib;})
      (import ./hyprland/addons/hyprpanel/config.nix {inherit config inputs pkgs lib;})
      (import ./hyprland/addons/hyprlock/config.nix {inherit config inputs pkgs lib;})
    ]))
  ];
}
