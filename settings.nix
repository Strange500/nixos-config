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
        desktop = {
          desktopEnvironment = "hyprland";
          loginManager = "ly";
          theme = "atelier-cave";
        };
      };
    };

    assertions = [
      {
        assertion =
          config.qgroget.nixos.desktop.desktopEnvironment
          == "hyprland"
          || config.qgroget.nixos.desktop.desktopEnvironment == "kde"
          || config.qgroget.nixos.desktop.desktopEnvironment == "gnome"
          || config.qgroget.nixos.desktop.desktopEnvironment == "none";
        message = "Only Hyprland, KDE, and GNOME are supported as desktop environments.";
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
        type = lib.types.str;
        default = "/var/lib/sops/age/keys.txt";
        description = "Path to the age key file for sops.";
      };
      user.username = lib.mkOption {
        type = lib.types.str;
        default = "strange";
        description = "The username for the qgroget user.";
      };
      server = {
        network.ip = lib.mkOption {
          type = lib.types.str;
          default = "192.168.0.34";
          description = "The IP address of the qgroget server.";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = "qgroget.com";
          description = "The domain for the qgroget server.";
        };
        test.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable test configurations for the qgroget server.";
        };
        containerDir = lib.mkOption {
          type = lib.types.str;
          default = "/etc/containersConfig";
          description = "Directory for container configurations.";
        };
      };
      nixos = {
        auto-update = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic updates for NixOS.";
        };
        isDesktop = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable basic apps (terminal, browser, file manager, etc.).";
        };
        apps = {
          school = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable school-related apps.";
          };
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
        theme = lib.mkOption {
          type = lib.types.str;
          default = "default";
          description = "Name of the desktop theme to use.";
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
        vr = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable VR configurations.";
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
          tailscale.autoConnect = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable automatic connection to Tailscale on network changes.";
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
