{
  lib,
  config,
  ...
}: {
  config = {
    qgroget.nixos = {
      remote-access = true;
      apps = {
        basic = true;
        sync = true;
        dev = {
          enable = true;
          jetbrains.enable = false;
        };
        media = true;
        crypto = true;
      };
      gaming = true;
      desktop = {
        desktopEnvironment = "hyprland";
        loginManager = "gdm";
        theme = "atelier-cave";
      };
    };

    assertions = [
      {
        assertion = config.qgroget.nixos.desktop.desktopEnvironment == "hyprland";
        message = "Hyprland is the only supported desktop environment.";
      }
      {
        assertion =
          config.qgroget.nixos.desktop.loginManager
          == "gdm"
          || config.qgroget.nixos.desktop.loginManager == "ly";
        message = "Only gdm and ly are supported as login managers.";
      }
    ];
  };

  options = {
    qgroget.nixos = {
      apps = {
        basic = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable basic apps (terminal, browser, file manager, etc.).";
        };
        sync = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable file synchronization with other nixos systems via qgroget.";
        };
        dev = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable development apps.";
          };
          jetbrains.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to enable JetBrains IDEs.";
          };
        };
        media = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable media apps.";
        };
        crypto = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable crypto apps.";
        };
      };
      desktop = {
        desktopEnvironment = lib.mkOption {
          type = lib.types.str;
          default = "hyprland";
          description = "The desktop environment to use.";
        };
        loginManager = lib.mkOption {
          type = lib.types.str;
          default = "gdm";
          description = "The login manager to use.";
        };
        monitors = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [", preferred, auto, 1"];
          description = "List of monitor configurations. (only for Hyprland)";
        };
        theme = lib.mkOption {
          type = lib.types.str;
          default = "atelier-cave";
          description = "The base16 theme to use";
        };
        background = lib.mkOption {
          type = lib.types.path;
          default = ./modules/desktop/stylix/wallpaper/apple-dark.jpg;
          description = "Path to the wallpaper";
        };
      };
      gaming = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable gaming apps and configurations.";
      };
      remote-access = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable remote access configurations.";
      };
      settings = {
        confDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/strange/nixos";
          description = "Path to the NixOS configuration directory.";
        };
      };
    };
  };
}
