{ inputs, pkgs, config, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.

  imports = [
    ../modules/monitors.nix
    ./hyprland.nix
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
  ### Hyprland ###

}
