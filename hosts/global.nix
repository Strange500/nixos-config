{
  inputs,
  pkgs,
  hostname,
  ...
}: {
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

    openssh = {
      enable = true;
      settings = {PermitRootLogin = "no";};
    };
  };

  virtualisation = {
    containers.enable = true;
    docker.enable = true;
    libvirtd.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  users.users.root.hashedPassword = "$6$13gz85QezPcMpTXb$jalGiNan9u2PYc3jP4zgUYoZqNcu.811AqfVNadcNQhH4kn9uWC0FxO7UPArX5Apm49lhDbQ5elFeBRS76.s.1";
  users.users.strange = {
    shell = pkgs.zsh;
    isNormalUser = true;
    home = "/home/strange";
    description = "strange";
    hashedPassword = "$6$tN1HR03Pv6LQFA.w$1byWSM0wWLFn6nQkYebqYLrPzYNf2eyqmGDvTqI8OET9M3y74in7lVGr1KJOHZQys6wWh.ggaRafH6fyrgPmm.";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "docker"
      "nix-users"
      "libvirtd"
      "kvm"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0BEci8hnaklKkXlnbagEMdf+/Ad7+USRH+ykQkYFdy strange@Clovis"
    ];
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

  fonts.packages = with pkgs; [pkgs.nerd-fonts.jetbrains-mono font-awesome];

  home-manager = {
    # also pass inputs to home-manager modules
    extraSpecialArgs = {inherit inputs pkgs;};
    users = {"strange" = import ../home.nix;};
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  nix = {
    settings = {
      trusted-users = ["root" "strange"];
      experimental-features = ["nix-command" "flakes"];
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
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];
    optimise.automatic = true;
  };

  networking.hostName = "${hostname}";

  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";

  system.stateVersion = "24.05";
}
