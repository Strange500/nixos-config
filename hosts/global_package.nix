{ inputs, pkgs, config, ... }:

{
    nixpkgs.config.allowUnfree = true;


    programs.firefox.enable = true;

    users.users.strange.packages = with pkgs; [
          rofi-wayland
          alacritty
          (jetbrains.plugins.addPlugins jetbrains.idea-ultimate ["github-copilot"])

          python3
    ];



    environment.systemPackages = [
         pkgs.rofi-wayland
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
         pkgs.swww
         pkgs.networkmanagerapplet
         pkgs.blueman
         pkgs.nix-prefetch-git
         pkgs.home-manager
         pkgs.libsForQt5.qt5.qtgraphicaleffects
         pkgs.pavucontrol
         inputs.swww.packages.${pkgs.system}.swww
        ];

}
