{ config, pkgs, inputs, ... }:

    {
    imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];


    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "nixos"; # Define your hostname.
    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/Paris";


    # Select internationalisation properties.
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

    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # bluetooth
    hardware.bluetooth.enable = true; # enables support for Bluetooth
    hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

    hardware.bluetooth.settings = { # more compatibility
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };

    systemd.user.services.mpris-proxy = { # allow heaset button to control
      description = "Mpris proxy";
      after = [ "network.target" "sound.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };

    # audio
    hardware.pulseaudio = {
        enable = false;
        package = pkgs.pulseaudioFull;
        support32Bit = true;
        extraConfig = "load-module module-combine-sink; unload-module module-suspend-on-idle;";
    };

    nixpkgs.config.pulseaudio = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.sddm = {
    enable = true;
    #    wayland.enable = true;
        theme = "${import ./sddm-theme.nix { inherit pkgs; }}";
        autoNumlock = true;
        package = pkgs.kdePackages.sddm;
        extraPackages = [
          pkgs.kdePackages.qt5compat
        ];
    };
    qt.enable = true;

    programs.hyprland = { # using Hyprland as WM
        enable = true;
        xwayland.enable = true;
        package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    };
    environment.sessionVariables = {
        #WLR_NO_HARDWARE_CURSORS = "1"; # uncomment if cursor is invisble
        NIXOS_OZONE_WL = "1";
    };

    hardware = {
        graphics.enable = true;
        nvidia.modesetting.enable = true;
    };
    # Configure keymap in X11
    services.xserver.xkb = {
        layout = "fr";
        variant = "";
    };

    home-manager = {
        # also pass inputs to home-manager modules
        extraSpecialArgs = {inherit inputs;};
        users = {
          "strange" = import ./home.nix;
        };
    };

    # Configure console keymap
    console.keyMap = "fr";

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    #  sound.enable = true;
    #  security.rtkit.enable = true;
    #  services.pipewire = {
    #    enable = true;
    #    alsa.enable = true;
    #    alsa.support32Bit = true;
    #    pulse.enable = true;
    #    # If you want to use JACK applications, uncomment this
    #    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    #  };

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.strange = {
        isNormalUser = true;
        description = "strange";
        extraGroups = [ "networkmanager" "wheel" "audio" ];
        packages = with pkgs; [
            #(callPackage "/etc/nixos/custom/sddmTheme.nix" {})
        ];
    };

    # Install firefox.
    programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = [
     pkgs.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     pkgs.wget
     pkgs.waybar
     pkgs.wlogout
     (pkgs.waybar.overrideAttrs (oldAttrs: {
           mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
           })
     )
     pkgs.dunst
     pkgs.libnotify
     pkgs.swww
     pkgs.kitty
     pkgs.rofi-wayland
     pkgs.networkmanagerapplet
     pkgs.blueman
     pkgs.vscode
     pkgs.home-manager
     pkgs.libsForQt5.qt5.qtgraphicaleffects
     pkgs.nerdfonts
    #     pkgs.qt6.full
    ];

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?

}

