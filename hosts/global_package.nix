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
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [thunar-archive-plugin thunar-volman];
    };
    virt-manager.enable = true;
    zsh.enable = true;
    dconf.enable = true;
  };

  xdg.portal.enable = true;

  environment.systemPackages = [
    pkgs.qemu
    pkgs.qemu_kvm
    pkgs.wget
    pkgs.blueman
    pkgs.nix-prefetch-git
    pkgs.home-manager
    pkgs.openrgb-with-all-plugins
    pkgs.brightnessctl
    pkgs.cachix
    pkgs.hypridle
    pkgs.nixd
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
    pkgs.plymouth
  ];
}
