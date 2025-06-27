{ config, pkgs, inputs, ... }:

    {
    imports =
    [ # Include the results of the hardware scan.
      ../global.nix
      ../../modules/config.nix
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelParams = [ "acpi_enforce_resources=lax" ];

    networking.hostName = "Septimius";
}

