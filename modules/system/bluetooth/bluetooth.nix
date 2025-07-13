{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.qgroget.nixos.settings.bluetooth.enable {
    hardware.bluetooth.enable = true; # enables support for Bluetooth
    hardware.bluetooth.powerOnBoot = true;

    hardware.bluetooth.settings = {
      # more compatibility
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
}
