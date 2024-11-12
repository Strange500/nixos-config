{ inputs, pkgs, config, ... }:

{


      hardware.bluetooth.enable = true; # enables support for Bluetooth
      hardware.bluetooth.powerOnBoot = true;


      hardware.bluetooth.settings = { # more compatibility
            General = {
              Enable = "Source,Sink,Media,Socket";
            };
          };



}
