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

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

  boot.kernelParams = ["acpi_enforce_resources=lax"];
  boot.binfmt.emulatedSystems = ["aarch64-linux"];
}
