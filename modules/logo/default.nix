{
  pkgs,
  lib,
  ...
}: let
  logo_text = ./assets/logo_text.png;
  logo = ./assets/logo.png;
  #logo_text_below = ./assets/logo_text_below.png;

  plymouth_width = 214;

  logo_plymouth =
    pkgs.runCommand "logo-plymouth" {
      buildInputs = [pkgs.imagemagick];
    } ''
      mkdir -p $out
      convert ${logo_text} -resize ${toString plymouth_width}x $out/logo.png
    '';

  authelia =
    pkgs.runCommand "logo-authelia" {
      buildInputs = [pkgs.imagemagick];
    } ''
      mkdir -p $out
      # main logo
      cp ${logo} $out/logo.png
      # logo to favicon.ico
      convert ${logo} -resize 48x48 $out/favicon.ico
    '';
  webLogo =
    pkgs.runCommand "logo-web" {
      buildInputs = [pkgs.imagemagick];
    } ''
      mkdir -p $out/img/server_branding
      cp ${logo} $out/img/server_branding/logo.png
      cp ${logo_text} $out/img/server_branding/logo_text.png
      #cp ''${logo_text_below} $out/img/server_branding/logo_text_below.png
    '';
in {
  options = {
    logo = {
      plymouth = lib.mkOption {
        type = lib.types.path;
        default = "${logo_plymouth}/logo.png";
        description = "Path to the logo image for plymouth.";
      };
      autheliaAssetsPath = lib.mkOption {
        type = lib.types.path;
        default = "${authelia}/";
        description = "Path to the directory containing Authelia logo assets.";
      };
      web = lib.mkOption {
        type = lib.types.path;
        default = "${webLogo}/";
        description = "Path to the directory containing web logo assets.";
      };
    };
  };
}
