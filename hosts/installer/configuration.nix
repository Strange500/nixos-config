{
  pkgs,
  modulesPath,
  config,
  ...
}: {
  imports = [
    ../../settings.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  environment.systemPackages = with pkgs; [vim git gparted];

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  nixpkgs.hostPlatform = "x86_64-linux";

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

  # Enable OpenSSH
  services.openssh.enable = true;

  # Allow root login (optional, insecure unless you add a key)
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0BEci8hnaklKkXlnbagEMdf+/Ad7+USRH+ykQkYFdy ${config.qgroget.user.username}@Clovis"
  ];

  # Set a root password
  users.users.root.initialPassword = "nixos";

  services.openssh.settings.PasswordAuthentication = false;

  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  nix = {
    settings = {
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
    optimise.automatic = true;
  };
}
