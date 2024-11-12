{ config, pkgs, inputs, ... }:

    {
    imports =
    [ # Include the results of the hardware scan.
      ../global.nix
      ../../modules/monitors.nix
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

    monitors = [
       {
        name = "DP-1";
        width = 2560;
        height = 1440;
        workspace = "1";
        primary = true;
        x = 0;
        y = 0;
        refreshRate = 60;
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

    networking.hostName = "NixLille"; # Define your hostname.

    home-manager = {
        # also pass inputs to home-manager modules
        extraSpecialArgs = {inherit inputs;};
        users = {
          "strange" = import ./home.nix;
        };
    };
}

