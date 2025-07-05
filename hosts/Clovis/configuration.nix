{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    useOSProber = true;
  };

  boot.kernelParams = ["acpi_enforce_resources=lax"];
}
