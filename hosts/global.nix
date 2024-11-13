{ inputs, pkgs, config, ... }:

{

      imports = [
        ./global_package.nix
        ../modules/audio/audio.nix
        ../modules/NetworkManager/NetworkManager.nix
        ../modules/login/sddm/sddm.nix
        ../modules/bluetooth/bluetooth.nix
        ../modules/polkit/polkit.nix
        ../modules/stylix/stylix.nix
      ];

      services.xserver.enable = true;
      qt.enable = true;

      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      users.users.strange = {
          isNormalUser = true;
          description = "strange";
          extraGroups = [ "networkmanager" "wheel" "audio" "docker" "nix-users" ];
      };



      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      time.timeZone = "Europe/Paris";
      i18n.defaultLocale = "fr_FR.UTF-8";

      i18n.extraLocaleSettings = {
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

      console.keyMap = "fr";
      services.printing.enable = true;

      hardware = {
              graphics.enable = true;
              nvidia.modesetting.enable = true;
          };
      environment.sessionVariables = {
                #WLR_NO_HARDWARE_CURSORS = "1"; # uncomment if cursor is invisble
                NIXOS_OZONE_WL = "1";
            };

      services.xserver.xkb = {
          layout = "fr";
          variant = "";
      };

      programs.hyprland = { # using Hyprland as WM
            enable = true;
            xwayland.enable = true;
            systemd.setPath.enable = true;
            package = inputs.hyprland.packages."${pkgs.system}".hyprland;
            portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          ll = "ls -l"; #
          update = "sudo nixos-rebuild switch --flake ~/nixos#$HOSTNAME";
        };
        oh-my-zsh = {
            enable = true;
            plugins = [ "git" "thefuck" ];
            theme = "robbyrussell";
          };

      };

      system.stateVersion = "24.05"; # Did you read the comment?

}
