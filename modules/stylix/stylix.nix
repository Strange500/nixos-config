{  inputs, pkgs, config, ... }:

{

      stylix.enable = true;
      stylix.polarity = "dark";
      stylix.opacity.desktop = 0.75;
      stylix.image = ./wallpaper/apple-dark.jpg;
      stylix.base16Scheme=  "${pkgs.base16-schemes}/share/themes/tomorrow-night.yaml";
      # tomorrow-night
      # ocean
      # gruvbox-dark
}

