{ lib, config, sops-nix, inputs, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.

  imports = [
    ./modules/monitors.nix
    ./modules/hyprland/hyprland.nix
    ./modules/waybar/waybar.nix
    ./modules/oh-my-zsh/oh-my-zsh.nix
    ./modules/kitty/kitty.nix
    inputs.sops-nix.homeManagerModule
  ];

  home.username = "strange";
  home.homeDirectory = "/home/strange";

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



  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  programs.starship = {
      enable = true;
      # Configuration written to ~/.config/starship.toml
      settings = {
        # add_newline = false;

        # character = {
        #   success_symbol = "[➜](bold green)";
        #   error_symbol = "[➜](bold red)";
        # };

        # package.disabled = true;
      };
    };

  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = true;
    enableUpdateCheck = true;
    extensions = with pkgs.vscode-extensions; [
            bbenoist.nix
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
            matthewpi.caddyfile-support
            jeff-hykin.better-nix-syntax
            dracula-theme.theme-dracula
            ms-vscode.cpptools-extension-pack
            ms-vscode-remote.remote-ssh
        ];
    userSettings = {
      "files.autoSave"= "afterDelay";
      "remote.SSH.configFile" = "/home/strange/ssh-config";
      "github.copilot.enable" = {
          "*" = true;
          "plaintext" = true;
          "markdown" = true;
          "scminput" = false;
      };
    };
  };

  programs.rofi = {
    enable = true;
    theme = lib.mkForce("/home/strange/.local/share/rofi/themes/theme.rasi") ;
  };

  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # BITWARDEN
      { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # METAMASK
    ];
  };


  home.stateVersion = "23.11";

  home.packages = [
    # EDITOR
    pkgs.lunarvim
    # Wallpaper
    pkgs.waypaper
    pkgs.swww

    # Utility for screenshots
    pkgs.grim
    pkgs.slurp

    # DEV
    # jetbrain with github copilot
    (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.webstorm ["github-copilot"])
    (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea-ultimate ["github-copilot"])


    # devbox for dependencies
    pkgs.devbox

    # Video
    pkgs.mpv

    # Text editor
    pkgs.libreoffice

    # Video editor
    # pkgs.kdePackages.kdenlive
    pkgs.davinci-resolve

    # Image Veiwer
    pkgs.qview

    # Archive manager
    pkgs.peazip

    pkgs.monero-gui

    pkgs.discord

    pkgs.blender

  ];

  home.file = {

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



   ".ssh/config".text = "Host *
    User strange
    IdentityFile '${config.sops.secrets."git/ssh/private".path}'
    ";
  };

  xdg.mimeApps.defaultApplications = {
    # Navigateurs
    "text/html" = "brave.desktop";
    "application/xhtml+xml" = "brave.desktop";
    
    # Documents
    "application/pdf" = "brave.desktop";
    "application/msword" = "libreoffice-writer.desktop";
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop"; # DOCX
    "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop"; # ODT
    
    # Images
    "image/png" = "qview.desktop"; # Un gestionnaire d'images
    "image/jpeg" = "qview.desktop";
    "image/gif" = "qview.desktop";
    "image/webp" = "qview.desktop"; 
    "image/bmp" = "qview.desktop";

    # Vidéos
    "video/mp4" = "mpv.desktop"; # Par exemple, MPV pour le lecteur vidéo
    "video/x-matroska" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    
    # Audio
    "audio/mpeg" = "mpv.desktop"; # Utilisation de mpv pour l'audio aussi
    "audio/flac" = "mpv.desktop";
    "audio/x-wav" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";

    # Archives
    "application/zip" = "peazip.desktop"; # Archive manager
    "application/x-rar" = "peazip.desktop"; # RAR
    "application/x-tar" = "peazip.desktop"; # TAR

    # Types de fichiers texte
    "text/plain" = "lvim.desktop"; # Éditeurs de texte
    "text/markdown" = "lvim.desktop";
    
    # Répertoires
    "inode/directory" = "thunar.desktop";

    # Autres types de fichiers
    "application/octet-stream" = "lvim.desktop"; # Fichiers génériques
  };

  home.sessionVariables = {
    EDITOR = "lvim";
    VISUAL = "lvim";
    BROWSER = "brave";
    TERMINAL = "kitty";
    FILE_MANAGER = "thunar";
  };

  # stylix = {
  #   cursor = {
  #     package = pkgs.vanilla-dmz;
  #     name = "Vanilla-DMZ";
  #     size = 32;
  #   };
  #   fonts = {
  #     serif = {
  #       package = pkgs.jetbrains-mono;
  #       name = "JetBrainsMono-Regular";
  #     };

  #     sansSerif = {
  #       package = pkgs.dejavu_fonts;
  #       name = "JetBrainsMono-Regular";
  #     };

  #     monospace = {
  #       package = pkgs.dejavu_fonts;
  #       name = "JetBrainsMono-Regular";
  #     };

  #     emoji = {
  #       package = pkgs.noto-fonts-emoji;
  #       name = "Noto Color Emoji";
  #     };
  #   };
  # };

  systemd.user.services.wallapaper-cycle = {
    Unit = {
      Description = "Cycle wallpaper using swww";
      After = [ "hyprland-session.target" ];
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.writeShellScript "wallpaper-cycle.sh" ''
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
            ''} /home/strange/wallpaper/current";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
