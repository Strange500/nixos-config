{lib, ...}: {
  options = {
    qgroget.nixos = {
      apps = {
        basic = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable basic apps (terminal, browser, file manager, etc.).";
        };
        sync = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable file synchronization with other nixos systems via qgroget.";
        };
        dev = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable development apps.";
          };
          jetbrains.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to enable JetBrains IDEs.";
          };
        };
        media = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable media apps.";
        };
        crypto = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable crypto apps.";
        };
      };
      settings = {
        confDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/strange/nixos";
          description = "Path to the NixOS configuration directory.";
        };
      };
    };
  };
}
