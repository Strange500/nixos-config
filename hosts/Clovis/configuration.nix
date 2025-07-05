{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/system/tpm/tpm.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.initrd.luks.devices = {
    cryptsystem = {
      device = lib.mkForce "/dev/nvme0n1p3";
    };
    cryptdata = {
      device = lib.mkForce "/dev/sda1";
    };
  };
}
