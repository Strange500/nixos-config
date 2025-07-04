{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  services.displayManager.gdm = {
    wayland = true;
    enable = true;
  };
}
