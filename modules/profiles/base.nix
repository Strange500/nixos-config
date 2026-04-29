{hostname, ...}: {
  imports = [
    ../options/qgroget.nix
    ../system/nix.nix
    ../system/locale.nix
    ../system/sops.nix
    ../users/primary.nix
    ../system/fonts.nix
    ../system/session.nix
    ../system/hardware.nix
    ../system/dev.nix
    ../system/home-manager.nix
    ../system/update/update.nix
    ../system/remoteAccess.nix
    ../shared
    ../logo
  ];

  networking.hostName = hostname;
  system.stateVersion = "24.05";
}
