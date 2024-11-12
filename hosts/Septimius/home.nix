{ config, pkgs, ... }:

let
    monitorConfig = [
      {
        name = "DP-1";
        primary = true;
        width = 2560;
        height = 1440;
        refreshRate = 60;
        position = "auto";
        enabled = true;
        workspace = "1";
      }
      {
        name = "HDMI-A-1";
        primary = false;
        width = 1920;
        height = 1080;
        refreshRate = 60;
        position = "auto";
        enabled = true;
        workspace = "2";
      }
   ];
in
{

  imports = [
    ../../home.nix
  ];

  monitors = monitorConfig;

  home.file = {

  };


  home.sessionVariables = {
    # EDITOR = "emacs";
  };

}
