{ config, pkgs, inputs, hostname, ... }:
{
    imports = [
      ../global.nix
      ../../modules/config.nix
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelParams = [ "acpi_enforce_resources=lax" ];

    networking.hostName = "${hostname}";
}
