{ inputs, pkgs, config, ... }:

{

      imports = [
        ./global_package.nix
        ../modules/audio/audio.nix
        ../modules/NetworkManager/NetworkManager.nix
        ../modules/login/ly/ly.nix
        ../modules/bluetooth/bluetooth.nix
        ../modules/polkit/polkit.nix
        ../modules/stylix/stylix.nix
        #../modules/oh-my-zsh/oh-my-zsh.nix
        #../modules/kitty/kitty.nix
      ];

     # users.defaultUserShell = pkgs.zsh;


      # Tailscale
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };


      services.xserver.enable = true;
      qt.enable = true;

      virtualisation.docker.enable = true;

      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;
      virtualisation.virtualbox.host.enable = true;
      virtualisation.virtualbox.host.enableExtensionPack = true;
      virtualisation.virtualbox.guest.enable = true;

      virtualisation.containers.enable = true;
        virtualisation = {
          podman = {
            enable = true;

            # Create a `docker` alias for podman, to use it as a drop-in replacement
            # dockerCompat = true;

            # Required for containers under podman-compose to be able to talk to each other.
            defaultNetwork.settings.dns_enabled = true;
          };
        };

      # Enable the OpenCL support for AMD GPUs (needed for davinci-resolve)
      hardware.amdgpu.opencl.enable = true;


      users.extraGroups.vboxusers.members = [ "strange" ];


      users.users.strange = {
          shell = pkgs.zsh;
          isNormalUser = true;
          description = "strange";
          extraGroups = [ "networkmanager" "wheel" "audio" "docker" "nix-users" "libvirtd" "kvm"];
      };




    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";

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
              ledger.enable = true;
          };
      environment.sessionVariables = {
                #WLR_NO_HARDWARE_CURSORS = "1"; # uncomment if cursor is invisble
                NIXOS_OZONE_WL = "1";
            };

      services.xserver.xkb = {
          layout = "fr";
          variant = "";
      };

      fonts.packages = with pkgs; [

        #powerline-fonts
        #powerline-symbols
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        font-awesome
      ];


      programs.hyprland = { # using Hyprland as WM
            enable = true;
            xwayland.enable = true;
            systemd.setPath.enable = true;
            package = inputs.hyprland.packages."${pkgs.system}".hyprland;
            portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };

      programs.zsh.enable = true;

    home-manager = {
            # also pass inputs to home-manager modules
            extraSpecialArgs = {inherit inputs pkgs;};
            users = {
              "strange" = import ../home.nix;
            };
        };

      system.stateVersion = "24.05"; # Did you read the comment?

}
