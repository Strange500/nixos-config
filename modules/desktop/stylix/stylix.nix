{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.isDesktop) {
    stylix.enable = true;
    stylix.opacity.desktop = 0.75;
    stylix.image = config.qgroget.nixos.desktop.background;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.qgroget.nixos.desktop.theme}.yaml";
    stylix.targets = {
      plymouth.enable = false;
      console.enable = false;
    };
  };
}
