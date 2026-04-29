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
      configPackages = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}
