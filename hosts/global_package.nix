{ inputs, pkgs, config, ... }:

{
    nixpkgs.config.allowUnfree = true;



    programs.thunar.enable = true;
    programs.xfconf.enable = true;
    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images

    programs.thunar.plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
    

    programs.dconf.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };


    environment.systemPackages = [
         pkgs.gsettings-desktop-schemas
         pkgs.qemu
         pkgs.qemu_kvm
         pkgs.quickemu
         pkgs.vim
         pkgs.emacs
         pkgs.wget
         pkgs.waybar
         pkgs.wlogout
         (pkgs.waybar.overrideAttrs (oldAttrs: {
               mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
               })
         )
         pkgs.dunst
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
         pkgs.nodePackages."@tailwindcss/language-server"

         pkgs.wireguard-tools

         # CRYPTO
         pkgs.ledger-live-desktop

         # Screen Brightness
         pkgs.brightnessctl
        
        
  ];

}
