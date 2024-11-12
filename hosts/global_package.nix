{ inputs, pkgs, config, ... }:

{
    nixpkgs.config.allowUnfree = true;


    programs.firefox.enable = true;

    users.users.strange.packages = with pkgs; [
          rofi-wayland
    ];



    environment.systemPackages = [
         pkgs.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
         pkgs.wget
         pkgs.waybar
         pkgs.wlogout
         #pkgs.lxqt.lxqt-policykit

         (pkgs.waybar.overrideAttrs (oldAttrs: {
               mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
               })
         )
         pkgs.dunst
         pkgs.libnotify
         pkgs.git
         pkgs.swww
         pkgs.kitty
         (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea-ultimate ["github-copilot"])
         (pkgs.jdk17.override { enableJavaFX = true; })
         pkgs.networkmanagerapplet
         pkgs.blueman
         pkgs.vscode
         pkgs.nix-prefetch-git

         pkgs.home-manager
         pkgs.libsForQt5.qt5.qtgraphicaleffects
         pkgs.nerdfonts
        ];

}
