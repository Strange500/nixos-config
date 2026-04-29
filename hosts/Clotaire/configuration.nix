{
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/profiles/base.nix
    ../../modules/profiles/desktop.nix
    ../../modules/profiles/gaming.nix
    ./settings.nix
    ./disk-config.nix
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
