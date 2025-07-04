{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  options = {
    login = {
      ly.enable = lib.mkEnableOption "Enables the ly display manager";
      gdm.enable = lib.mkEnableOption "Enables the GDM display manager";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(config.login.ly.enable && config.login.gdm.enable);
          message = "Cannot enable both ly and GDM display managers simultaneously. Please choose only one.";
        }
        {
          assertion = config.login.ly.enable -> (config.login.ly.enable || config.login.gdm.enable);
          message = "At least one display manager must be enabled when login module is used.";
        }
      ];
    }

    (lib.mkIf config.login.ly.enable (import ./ly/ly.nix {inherit pkgs config inputs lib;}))
    (lib.mkIf config.login.gdm.enable (import ./gdm/gdm.nix {inherit pkgs config inputs lib;}))
  ];
}
