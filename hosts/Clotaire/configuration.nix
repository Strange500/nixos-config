{
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../global.nix
    ./disk-config.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/system/tpm/tpm.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # boot.initrd.luks.devices = {
  #   cryptsystem = {
  #     device = lib.mkForce "/dev/nvme0n1p3";
  #   };
  # };

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

  services.upower.enable = true;

  boot.kernelParams = ["acpi_enforce_resources=lax"];
}
