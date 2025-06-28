{ inputs, pkgs, config, ... }:
{
    imports = [
        ./global_package.nix
        ../modules/audio/audio.nix
        ../modules/NetworkManager/NetworkManager.nix
        ../modules/login/ly/ly.nix
        ../modules/bluetooth/bluetooth.nix
        ../modules/stylix/stylix.nix
        ./setting.nix
    ];

    services = {
        tailscale = {
            enable = true;
            useRoutingFeatures = "client";
        };
        xserver.xkb = {
            layout = "fr";
            variant = "";
        };
        printing.enable = true;
        hardware.openrgb = {
            enable = true;
            package = pkgs.openrgb-with-all-plugins;
            motherboard = "amd";
        };
        gvfs.enable = true;
    };

    virtualisation = {
        containers.enable = true;
        docker.enable = true;
        libvirtd.enable = true;
    };

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    users.users.strange = {
      shell = pkgs.zsh;
      isNormalUser = true;
      home = "/home/strange";
      description = "strange";
      extraGroups = [ "networkmanager" "wheel" "audio" "docker" "nix-users" "libvirtd" "kvm"];
    };

    i18n = {
      defaultLocale = "fr_FR.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "fr_FR.UTF-8";
        LC_IDENTIFICATION = "fr_FR.UTF-8";
        LC_MEASUREMENT = "fr_FR.UTF-8";
        LC_MONETARY = "fr_FR.UTF-8";
        LC_NAME = "fr_FR.UTF-8";
        LC_NUMERIC = "fr_FR.UTF-8";
        LC_PAPER = "fr_FR.UTF-8";
        LC_TELEPHONE = "fr_FR.UTF-8";
        LC_TIME = "fr_FR.UTF-8";
        };
    };

    hardware = {
          graphics.enable = true;
          nvidia.modesetting.enable = true;
          ledger.enable = true;
      };

    environment.sessionVariables = {
            #WLR_NO_HARDWARE_CURSORS = "1"; # uncomment if cursor is invisble
            NIXOS_OZONE_WL = "1";
        };

    fonts.packages = with pkgs; [
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        font-awesome
    ];

    home-manager = {
        # also pass inputs to home-manager modules
        extraSpecialArgs = {inherit inputs pkgs;};
        users = {
          "strange" = import ../home.nix;
        };
    };

    nixpkgs.config = {
            allowUnfree = true;
            allowUnfreePredicate = (_: true);
        };

    nix = {
        settings = {
            trusted-users = [ "root" "strange" ];
            experimental-features = [ "nix-command" "flakes" ];
            substituters = [
                "https://nix-community.cachix.org"
                "https://cache.nixos.org/"
                "https://hyprland.cachix.org"
            ];
            trusted-substituters = ["https://hyprland.cachix.org"];
            trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            ];
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
        optimise.automatic = true;
    };


    time.timeZone = "Europe/Paris";
    console.keyMap = "fr";

    system.stateVersion = "24.05";
}
