{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  monitors =
    config.settings.monitors or [
      ", preferred, auto, 1"
    ];
in {
  imports = [
    ./settings.nix
    ./modules/config.nix
    ./modules/desktop/hyprDesktop.nix
    ./modules/apps/desktopsApps.nix
    inputs.sops-nix.homeManagerModule
  ];

  qgroget.nixos = {
    # remote-access = true;
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
    # gaming = true;
    # desktop = {
    #   desktopEnvironment = "hyprland";
    #   loginManager = "gdm";
    #   monitors = monitors;
    # };
  };

  desktop.hyprDesktop = {
    enable = true;
    settings = {
      monitor = monitors;
    };
  };

  home = {
    username = "strange";
    homeDirectory = "/home/strange";
    stateVersion = "23.11";
    packages = [
      pkgs.swww
      pkgs.grim
      pkgs.slurp
      pkgs.discord
      pkgs.hyprpanel
      pkgs.moonlight-qt
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
      "wallpaper/current" = {
        source = ./home/wallpapers/current;
        recursive = true;
      };
      # syncthing ignore hidden files
      ".stignore".text = ''
        .*
                  *.tmp
                  *.log
                  *~
                  *.swp
                  .DS_Store
                  wallpaper
                  nixos'';

      ".ssh/config".text = "Host *\n          User strange\n          IdentityFile '${
        config.sops.secrets."git/ssh/private".path
      }'\n          ";
    };
  };

  sops = {
    age.keyFile = "/home/strange/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/secrets.yaml;

    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets."git/ssh/private" = {
      path = "${config.sops.defaultSymlinkPath}/git/ssh/private";
    };

    secrets."wireguard/conf" = {
      path = "${config.sops.defaultSymlinkPath}/wireguard/conf";
      #path = "./wireguard/conf";
    };
  };

  programs.rofi = {
    enable = true;
    theme = lib.mkForce "/home/strange/.local/share/rofi/themes/theme.rasi";
  };

  systemd.user.services.wallapaper-cycle = {
    Unit = {
      Description = "Cycle wallpaper using swww";
      After = ["hyprland-session.target"];
    };
    Install = {WantedBy = ["hyprland-session.target"];};
    Service = {
      Type = "simple";
      ExecStart = "${
        pkgs.writeShellScript "wallpaper-cycle.sh" ''
          # This script automatically changes wallpaper for Linux desktop using Hyprland as DP

          WAIT=300
          dir=$1
          trans_type="any"

          swww-daemon &

          # Define the function for setting wallpapers in Hyprland
          set_wallpaper_hyprland() {
              BG="$(find "$dir" -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' | shuf -n1)"
              PROGRAM="swww-daemon"

              for dp in $(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}'); do
                  BG="$(find "$dir" -name '*.jpg' -o -name '*.png' | shuf -n1)"
                  swww img "$BG" --transition-fps 244 --transition-type "$trans_type" --transition-duration 1 -o "$dp"
                  sleep 1
              done

          }

          # Main loop to check for monitor configuration changes and update wallpaper
          while true; do
              initial_monitors=$(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}')
              set_wallpaper_hyprland
              # Wait for the specified amount of time or until a monitor configuration change
              for ((i=1; i<=WAIT; i++)); do
                  current_monitors=$(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}')
                  if [ "$initial_monitors" != "$current_monitors" ]; then
                      echo "Monitor configuration changed. Breaking out of the loop."
                      break
                  fi
                  sleep 1
              done
          done
        ''
      } /home/strange/wallpaper/current";
    };
  };
  programs.home-manager.enable = true;
}
