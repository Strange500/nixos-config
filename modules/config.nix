{lib, ...}: {
  options = {
    settings = {
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["HDMI-A-1, 1920x1080, 0x0, 1" "DP-2, 2560x1440@144, 1920x0, 1"];
        description = "List of monitors with their specifications.";
      };
      stylix = lib.mkOption {
        type = lib.types.submodule {
          options = {
            theme = lib.mkOption {
              type = lib.types.str;
              default = "atelier-cave";
              description = "The base16 theme to use with Stylix.";
            };
            image = lib.mkOption {
              type = lib.types.path;
              default = ./desktop/stylix/wallpaper/apple-dark.jpg;
              description = "Path to the wallpaper image used by Stylix.";
            };
          };
        };
      };
      confDirectory = lib.mkOption {
        type = lib.types.str;
        default = "/home/strange/nixos";
        description = "The directory where the NixOS configuration files are stored.";
      };
    };
  };
}
