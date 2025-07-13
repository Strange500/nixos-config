{
  inputs,
  pkgs,
  hostname,
  lib,
  config,
  ...
}: {
  imports = [
    ../settings.nix
    ./global_package.nix
    ../modules/system/audio/audio.nix
    ../modules/system/login/login.nix
    ../modules/system/bluetooth/bluetooth.nix
    ../modules/desktop/stylix/stylix.nix
    ../modules/system/boot/plymouth.nix
    ../modules/system/update/update.nix
    ../modules/game/game.nix
    ../modules/system/remoteAccess.nix
    ./setting.nix
  ];

  networking.networkmanager = {enable = true;};
  services = {
    xserver.xkb = {
      layout = "fr";
      variant = "";
    };
    printing.enable = true;
    gvfs.enable = true;
  };

  virtualisation = lib.mkIf (config.qgroget.nixos.apps.dev.enable) {
    containers.enable = true;
    docker.enable = true;
    libvirtd.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  users.users.root.hashedPassword = "$6$13gz85QezPcMpTXb$jalGiNan9u2PYc3jP4zgUYoZqNcu.811AqfVNadcNQhH4kn9uWC0FxO7UPArX5Apm49lhDbQ5elFeBRS76.s.1";
  users.users.${config.qgroget.user.username} = {
    shell = pkgs.zsh;
    isNormalUser = true;
    home = "/home/${config.qgroget.user.username}";
    description = "${config.qgroget.user.username}";
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
  };

  environment.etc."gitconfig".text = ''
    [safe]
      directory = /home/${config.qgroget.user.username}/nixos
  '';

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
    ledger.enable = true;
  };

  environment.sessionVariables = {
    #WLR_NO_HARDWARE_CURSORS = "1"; # uncomment if cursor is invisble
    NIXOS_OZONE_WL = "1";
  };

  fonts.packages = with pkgs; [pkgs.nerd-fonts.jetbrains-mono font-awesome];

  home-manager.backupFileExtension = "backup";

  home-manager = {
    extraSpecialArgs = {inherit inputs pkgs hostname;};
    users = {"${config.qgroget.user.username}" = import ../home.nix;};
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  nix = {
    settings = {
      trusted-users = ["root" "${config.qgroget.user.username}"];
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
