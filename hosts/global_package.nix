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
    virt-manager.enable = config.qgroget.nixos.isDesktop;
    zsh.enable = true;
    dconf.enable = config.qgroget.nixos.isDesktop;
  };

  services = {
    desktopManager.plasma6.enable = lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "kde";
    desktopManager.gnome.enable = lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "gnome";
  };

  xdg.portal.enable = config.qgroget.nixos.isDesktop;

  environment.systemPackages = lib.mkIf config.qgroget.nixos.isDesktop (
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
    ++ lib.optionals (config.qgroget.nixos.remote-access.sunshine.enable) [
      pkgs.sunshine
    ]
  );
}
