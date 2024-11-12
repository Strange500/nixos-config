{ inputs, pkgs, config, ... }:

{

      imports = [
        ./global_package.nix
        ../modules/audio/audio.nix
        ../modules/NetworkManager/NetworkManager.nix
        ../modules/login/sddm/sddm.nix
        ../modules/bluetooth/bluetooth.nix
        ../modules/polkit/polkit.nix
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

      services.xserver.xkb = {
          layout = "fr";
          variant = "";
      };

      system.stateVersion = "24.05"; # Did you read the comment?

}
