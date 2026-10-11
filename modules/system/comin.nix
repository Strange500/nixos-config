{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.nixos.comin;
in {
  config = lib.mkIf cfg.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/Strange500/nixos-config.git";
          branches.main.name = "main";
        }
      ];
    };
  };
}