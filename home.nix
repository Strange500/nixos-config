{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./settings.nix
    ./hosts/setting.nix
    ./modules/desktop/hyprDesktop.nix
    ./modules/apps/desktopsApps.nix
    ./modules/shared
    inputs.sops-nix.homeManagerModule
  ];

  home = {
    username = "${config.qgroget.user.username}";
    homeDirectory = "/home/${config.qgroget.user.username}";
    stateVersion = "25.11";
    packages = lib.mkIf (config.qgroget.nixos.isDesktop) [
      pkgs.discord
      pkgs.moonlight-qt
      pkgs.nautilus

      pkgs.kdePackages.kirigami
      pkgs.kdePackages.kirigami-addons # Often required alongside kirigami
      pkgs.kdePackages.qqc2-desktop-style # Helps with theming

      inputs.quickshell.packages.${pkgs.system}.default # Quickshell from flake input
    ];

    sessionVariables = lib.mkIf (config.qgroget.nixos.isDesktop) {
      QML2_IMPORT_PATH = "${pkgs.kdePackages.kirigami}/lib/qt-6/qml:${pkgs.kdePackages.kirigami-addons}/lib/qt-6/qml:${pkgs.kdePackages.qqc2-desktop-style}/lib/qt-6/qml";
    };
    file = {
      ".config" = {
        source = ./home/.config;
        recursive = true;
      };
      ".local" = {
        source = ./home/.local;
        recursive = true;
      };
      "wallpaper/${config.qgroget.nixos.theme}" = {
        source = ./home/wallpapers/${config.qgroget.nixos.theme};
        recursive = true;
      };
      ".ssh/config".text = "Host *\n          User ${config.qgroget.user.username}\n          IdentityFile '${
        config.sops.secrets."git/ssh/private".path
      }'\n          ";
    };
  };

  sops = {
    age.keyFile = "${config.qgroget.secretAgeKeyPath}";
    defaultSopsFile = ./secrets/secrets.yaml;

    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets = {
      "git/ssh/private" = {
        path = "${config.sops.defaultSymlinkPath}/git/ssh/private";
      };
    };
  };

  programs.home-manager.enable = true;
}
