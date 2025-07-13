{
  lib,
  config,
  ...
}: {
  config = {
    qgroget = {
      secretAgeKeyPath = "/var/lib/sops/age/keys.txt";
      user.username = "strange";
      nixos = {
        apps = {
          basic = true;
        };
        desktop = {
          desktopEnvironment = "hyprland";
          loginManager = "gdm";
          theme = "atelier-cave";
        };
      };
    };

    assertions = [
      {
        assertion =
          config.qgroget.nixos.desktop.desktopEnvironment
          == "hyprland"
          || config.qgroget.nixos.desktop.desktopEnvironment == "kde";
        message = "Only Hyprland and KDE are supported as desktop environments.";
      }
      {
        assertion =
          config.qgroget.nixos.desktop.loginManager
          == "gdm"
          || config.qgroget.nixos.desktop.loginManager == "ly"
          || config.qgroget.nixos.desktop.loginManager == "none";
        message = "Only gdm and ly are supported as login managers.";
      }
    ];
  };

  options = {
    qgroget = {
      secretAgeKeyPath = lib.mkOption {
        type = lib.types.string;
        default = "/var/lib/sops/age/keys.txt";
        description = "Path to the age key file for sops.";
      };
      user.username = lib.mkOption {
        type = lib.types.str;
        default = "strange";
        description = "The username for the qgroget user.";
      };
      nixos = {
        auto-update = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic updates for NixOS.";
        };
        apps = {
          basic = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable basic apps (terminal, browser, file manager, etc.).";
          };
          sync = {
            desktop.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable file synchronization with other nixos systems via qgroget.";
            };
            game.enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable game synchronization with other nixos systems via qgroget.";
            };
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
        remote-access = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable remote access configurations.";
          };
          tailscale.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Tailscale for remote access.";
          };
          sunshine.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Sunshine for game streaming.";
          };
        };
        settings = {
          confDirectory = lib.mkOption {
            type = lib.types.str;
            default = "/home/strange/nixos";
            description = "Path to the NixOS configuration directory.";
          };
          bluetooth.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Bluetooth support.";
          };
        };
      };
    };
  };
}
