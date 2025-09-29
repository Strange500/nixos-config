{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  programs = {
    hyprland = lib.mkIf (config.qgroget.nixos.desktop.desktopEnvironment == "hyprland") {
      enable = true;
      xwayland.enable = true;
      systemd.setPath.enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    zsh.enable = true;
    dconf.enable = true;
  };

  services = {
    desktopManager.plasma6 = lib.mkIf (lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "kde") {
      enable = true;
    };
    desktopManager.gnome = lib.mkIf (lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "gnome") {
      enable = true;
    };
  };
  services.xserver.displayManager.startx.enable = true;

  xdg.portal.enable = true;

  environment.systemPackages = (
    [
      pkgs.git
      pkgs.wget
      pkgs.blueman
      pkgs.nix-prefetch-git
      pkgs.home-manager
      pkgs.gparted
      pkgs.cachix
      pkgs.nixd
      pkgs.plymouth
      pkgs.wl-clipboard
    ]
    ++ lib.optionals (config.qgroget.nixos.desktop.desktopEnvironment == "hyprland") [
      pkgs.hyprpolkitagent
      pkgs.hypridle
      inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
    ]
    ++ lib.optionals (config.qgroget.nixos.desktop.desktopEnvironment == "kde") [
      pkgs.kdePackages.ksystemlog
      pkgs.wayland-utils
    ]
    ++ lib.optionals (config.qgroget.nixos.desktop.desktopEnvironment == "gnome") [
      pkgs.gnome-session
      pkgs.gnome-shell
      pkgs.gnome-control-center
    ]
    ++ lib.optionals (config.qgroget.nixos.remote-access.sunshine.enable) [
      pkgs.sunshine
    ]
  );
}
