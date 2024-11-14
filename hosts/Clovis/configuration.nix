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

    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";

    ## put age key here
    sops.age.keyFile = "/home/strange/.config/sops/age/keys.txt";

    sops.secrets."git/ssh/private" = {
      owner = "strange";
    };

    sops.secrets."wireguard/conf" = {
          owner = "strange";
        };

    monitors = [
       {
        name = "DP-1";
        width = 2560;
        height = 1440;
        workspace = "1";
        primary = true;
        x = 0;
        y = 0;
        refreshRate = 144;
        enabled = true;
       }
       {
        name = "HDMI-A-2";
        width = 1920;
        height = 1080;
        workspace = "2";
        x = 1440;
        y = 0;
        refreshRate = 60;
        enabled = true;
       }
      ];


    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelParams = [ "acpi_enforce_resources=lax" ];

    networking.hostName = "Clovis"; # Define your hostname.

    home-manager = {
        # also pass inputs to home-manager modules
        extraSpecialArgs = {inherit inputs pkgs;};
        users = {
          "strange" = import ./home.nix;
        };
    };
}

