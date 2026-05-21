{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.isDesktop) {
    networking.networkmanager.enable = true;

    services = {
      xserver.xkb = {
        layout = "fr";
        variant = "";
      };
      printing.enable = true;
      gvfs.enable = true;
    };

    xdg.portal = {
      enable = true;
      wlr.enable = lib.mkIf (config.qgroget.nixos.desktop.desktopEnvironment == "hyprland") true;
      extraPortals = lib.optionals (config.qgroget.nixos.desktop.desktopEnvironment == "niri") [
        pkgs.xdg-desktop-portal-gnome
      ];
      configPackages = [pkgs.xdg-desktop-portal-gtk];
      config = {
        common.default = ["gtk"];
        niri.default = ["gnome" "gtk"];
      };
    };
  };
}
