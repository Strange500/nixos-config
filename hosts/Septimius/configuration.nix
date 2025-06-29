{ config, pkgs, inputs, ... }: {
  imports = [
    ../global.nix
    ../../modules/config.nix
    ./disk-config.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
}
