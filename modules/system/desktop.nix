{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.isDesktop) {
    networking.networkmanager.enable = true;

    # Workaround for the GTK/Firefox Wayland clipboard bug where copying from
    # Firefox (a GTK app) fails to reach non-GTK apps (e.g. VSCode/Electron).
    # GTK_USE_PORTAL=1 routes GTK clipboard through xdg-desktop-portal instead
    # of the native Wayland selection protocol, which the compositor resolves
    # more reliably. Upstream bug (not NixOS-specific):
    # https://bugzilla.mozilla.org/show_bug.cgi?id=1791417
    environment.sessionVariables = lib.mkIf (
      config.qgroget.nixos.desktop.desktopEnvironment == "niri"
    ) {
      GTK_USE_PORTAL = "1";
    };

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
