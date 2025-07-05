{
  pkgs,
  config,
  lib,
  ...
}: {
  stylix.enable = true;
  stylix.opacity.desktop = 0.75;
  stylix.image = config.settings.stylix.image;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.settings.stylix.theme}.yaml";
  stylix.targets = {
    plymouth.enable = false;
    console.enable = false;
  };
}
