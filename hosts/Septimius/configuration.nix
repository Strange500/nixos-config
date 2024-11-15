{ config, pkgs, inputs, ... }:

    {
    imports =
    [ # Include the results of the hardware scan.
      ../global.nix
      ../../modules/monitors.nix
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];



    monitors = [
       {
        name = "DP-1";
        width = 1920;
        height = 1080;
        workspace = "1";
        primary = true;
        x = 0;
        y = 0;
        refreshRate = 60;
        enabled = true;
       }
      ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelParams = [ "acpi_enforce_resources=lax" ];

    networking.hostName = "Clovis"; # Define your hostname.


}

