{hostname, ...}: {
  imports = [
    ../options/qgroget.nix
    ../system/nix.nix
    ../system/nix-cache.nix
    ../system/locale.nix
    ../system/sops.nix
    ../users/primary.nix
    ../system/fonts.nix
    ../system/session.nix
    ../system/hardware.nix
    ../system/dev.nix
    ../system/home-manager.nix
    ../system/update/update.nix
    ../system/comin.nix
    ../system/remoteAccess.nix
    ../shared
    ../logo
  ];

  networking.hostName = hostname;
  system.stateVersion = "24.05";

  # Every host pulls from the self-hosted harmonia cache on Server. nix queries
  # it alongside cache.nixos.org and falls back on cache miss (e.g. the aarch64
  # pi, whose closures the x86_64 cache can never serve).
  qgroget.nix-cache.enable = true;
}
