{
  pkgs,
  config,
  lib,
  ...
}: {
  options.settings.stylix = lib.mkOption {
    type = lib.types.submodule {
      options = {
        theme = lib.mkOption {
          type = lib.types.str;
          default = "atelier-cave";
          description = "The base16 theme to use with Stylix.";
        };
        image = lib.mkOption {
          type = lib.types.path;
          default = ./wallpaper/apple-dark.jpg;
          description = "Path to the wallpaper image used by Stylix.";
        };
      };
    };
    description = "Configuration for Stylix, a wallpaper and theming tool.";
  };

  config = {
    stylix.enable = true;
    stylix.opacity.desktop = 0.75;
    stylix.image = config.settings.stylix.image;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.settings.stylix.theme}.yaml";
    stylix.targets = {
      plymouth.enable = false;
      console.enable = false;
    };
  };
}
