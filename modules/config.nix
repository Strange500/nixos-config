{ lib, ... }: {
  options = {
    settings = {
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default =
          [ "HDMI-A-1, 1920x1080, 0x0, 1" "DP-2, 2560x1440@144, 1920x0, 1" ];
        description = "List of monitors with their specifications.";
      };
      stylix = {
        theme = lib.mkOption {
          type = lib.types.str;
          default = "tomorrow-night";
          description = "The base16 theme to use with Stylix.";
        };
      };
    };
  };
}
