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
    dconf.enable = lib.mkIf (config.qgroget.nixos.isDesktop) true;
    dank-material-shell.enable =
      lib.mkIf (
        config.qgroget.nixos.desktop.desktopEnvironment == "niri"
      )
      true;
  };

  programs.niri = lib.mkIf (config.qgroget.nixos.desktop.desktopEnvironment == "niri") {
    enable = true;
    package = pkgs.niri;
  };

  services = {
    desktopManager.plasma6 =
      lib.mkIf (lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "kde")
      {
        enable = true;
      };
    desktopManager.gnome =
      lib.mkIf (lib.strings.toLower config.qgroget.nixos.desktop.desktopEnvironment == "gnome")
      {
        enable = true;
      };
  };
  services.xserver.displayManager.startx.enable = lib.mkIf (config.qgroget.nixos.isDesktop) true;

  environment.systemPackages = (
    [
      pkgs.git
      pkgs.wget
      pkgs.home-manager
    ]
    ++ lib.optionals (config.qgroget.nixos.isDesktop) [
      pkgs.plymouth
      pkgs.wl-clipboard
      pkgs.gparted
      pkgs.blueman
      pkgs.kdePackages.dolphin
      pkgs.kdePackages.kio
      pkgs.kdePackages.qtsvg
    ]
    ++ lib.optionals (config.qgroget.nixos.apps.dev.enable) [
      pkgs.nixd
      pkgs.delta
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
    ++ lib.optionals (config.qgroget.nixos.desktop.desktopEnvironment == "niri") [
      pkgs.pywalfox-native
      pkgs.xwayland-satellite
    ]
  );
}
