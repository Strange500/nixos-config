{
  lib,
  config,
  sops-nix,
  inputs,
  pkgs,
  ...
}: let
  pluginListInte = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".idea-ultimate."2025.1"."com.github.copilot"
  ];
  pluginListWeb = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".webstorm."2025.1"."com.github.copilot"
  ];
in {
  imports = [
    ./modules/config.nix
    ./modules/hyprland/hyprland.nix
    ./modules/firefox/firefox.nix
    ./modules/syncthing/syncthing.nix
    ./modules/hypridle/config.nix
    ./modules/hyprlock/config.nix
    ./modules/oh-my-zsh/oh-my-zsh.nix
    ./modules/kitty/kitty.nix
    inputs.sops-nix.homeManagerModule
  ];

  home = {
    username = "strange";
    homeDirectory = "/home/strange";
    stateVersion = "23.11";
    packages = [
      pkgs.lunarvim
      pkgs.swww
      pkgs.grim
      pkgs.slurp
      (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.webstorm pluginListWeb)
      (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea-ultimate
        pluginListInte)
      pkgs.devbox
      pkgs.mpv
      pkgs.discord
      pkgs.hyprpanel
      pkgs.moonlight-qt
      pkgs.unzip
      pkgs.unrar
      pkgs.zip
      pkgs.git
      pkgs.libnotify
      pkgs.pre-commit
      pkgs.alejandra
      pkgs.ledger-live-desktop
      pkgs.nixd
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
    sessionVariables = {
      EDITOR = "lvim";
      VISUAL = "lvim";
      BROWSER = "brave";
      TERMINAL = "kitty";
      FILE_MANAGER = "thunar";
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

  programs = {
    starship.enable = true;
    vscode = {
      enable = true;
      profiles.default = {
        enableExtensionUpdateCheck = true;
        enableUpdateCheck = true;
        extensions = with pkgs.vscode-extensions; [
          zainchen.json
          github.copilot
          github.copilot-chat
          ms-vscode.live-server
          oderwat.indent-rainbow
          esbenp.prettier-vscode
          dbaeumer.vscode-eslint
          codezombiech.gitignore
          yoavbls.pretty-ts-errors
          vscjava.vscode-java-pack
          mechatroner.rainbow-csv
          bradlc.vscode-tailwindcss
          ms-azuretools.vscode-docker
          ms-vscode.cpptools-extension-pack
          ms-vscode-remote.remote-ssh
        ];
        userSettings = {
          "files.autoSave" = "afterDelay";
          "remote.SSH.configFile" = "/home/strange/ssh-config";
          "github.copilot.enable" = {
            "*" = true;
            "plaintext" = true;
            "markdown" = true;
            "scminput" = false;
          };
          "nix.serverPath" = "nixd";
          "nix.enableLanguageServer" = true;
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = ["alejandra"];
              };
              "options" = {
                "nixos" = {
                  "expr" = "(builtins.getFlake \"${config.confDirectory}\").nixosConfigurations.Clovis.options";
                };
                #"home_manager" = {
                #  "expr" = "(builtins.getFlake \"${config.confDirectory}\").homeConfigurations.Clovis.options";
                #};
              };
            };
          };
        };
      };
    };

    rofi = {
      enable = true;
      theme = lib.mkForce "/home/strange/.local/share/rofi/themes/theme.rasi";
    };

    chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # Ublock Origin
        {id = "nngceckbapebfimnlniiiahkandclblb";} # BITWARDEN
        {id = "nkbihfbeogaeaoehlefnkodbefgpgknn";} # METAMASK
      ];
    };
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
