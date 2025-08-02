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
    inputs.sops-nix.homeManagerModule
  ];

  xdg.configFile."openxr/1/active_runtime.json".source = lib.mkIf config.qgroget.nixos.vr "${pkgs.monado}/share/openxr/1/openxr_monado.json";


  home = {
    username = "${config.qgroget.user.username}";
    homeDirectory = "/home/${config.qgroget.user.username}";
    stateVersion = "25.11";
    packages = [
      pkgs.discord
      pkgs.moonlight-qt
      pkgs.nautilus
    ];
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

    secrets."git/ssh/private" = {
      path = "${config.sops.defaultSymlinkPath}/git/ssh/private";
    };
  };

  programs.home-manager.enable = true;
}
