{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.java = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    enable = true;
    package = pkgs.openjdk21;
  };

  users.extraGroups.vboxusers.members = lib.mkIf config.qgroget.nixos.apps.dev.enable [
    config.qgroget.user.username
  ];

  boot.kernelModules = lib.mkIf config.qgroget.nixos.apps.dev.vbox.enable [
    "vboxdrv"
    "vboxnetadp"
    "vboxnetflt"
    "vboxpci"
  ];

  virtualisation = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    containers.enable = true;
    libvirtd.enable = true;
  };
}
