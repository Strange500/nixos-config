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
    };
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
    pkgs.hyprpaper

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

  ];

  home.file = {


   ".config" = {
        source = ./home/.config;
        recursive = true;
   };

   "wallpaper" = {
              source = ./home/wallpapers;
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
