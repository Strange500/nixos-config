{ pkgs, inputs, hostname, ... }:
{
    imports = [
        ../global.nix
        ../../modules/config.nix
        inputs.home-manager.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        ./disk-config.nix
        ];

    boot.loader.grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
        useOSProber = true;
    };

    boot.kernelParams = [ "acpi_enforce_resources=lax" ];

    networking.hostName = "${hostname}";
}
