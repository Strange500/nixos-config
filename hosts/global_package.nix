{ inputs, pkgs, config, ... }:

{
    nixpkgs.config.allowUnfree = true;
    programs.thunar.enable = true;
    programs.xfconf.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    programs.thunar.plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];

    programs.dconf.enable = true;

    programs.steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
    };


    environment.systemPackages = [
         pkgs.gsettings-desktop-schemas
         pkgs.qemu
         pkgs.qemu_kvm
         pkgs.vim
         pkgs.wget
         pkgs.wlogout
         (pkgs.waybar.overrideAttrs (oldAttrs: {
               mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
               })
         )
         pkgs.libnotify
         pkgs.git
         pkgs.networkmanagerapplet
         pkgs.blueman
         pkgs.nix-prefetch-git
         pkgs.home-manager
         pkgs.libsForQt5.qt5.qtgraphicaleffects
         pkgs.pavucontrol
         pkgs.openrgb-with-all-plugins
         pkgs.gtk3
         pkgs.wireguard-tools
         pkgs.ledger-live-desktop
         pkgs.brightnessctl
  ];

}
