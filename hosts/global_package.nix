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

  environment.systemPackages =
    [
      pkgs.wget
      pkgs.blueman
      pkgs.nix-prefetch-git
      pkgs.home-manager
      pkgs.gparted
      pkgs.cachix
      pkgs.nixd
      pkgs.plymouth
    ]
    ++ lib.optionals (config.qgroget.nixos.desktop.desktopEnvironment == "hyprland") [
      pkgs.hyprpolkitagent
      pkgs.hypridle
      inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
    ];
}
