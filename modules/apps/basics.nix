{
  pkgs,
  lib,
  config,
  ...
}: {
  home = lib.mkIf config.qgroget.nixos.apps.basic {
    packages = with pkgs; [
      lunarvim
      unzip
      unrar
      zip
      git
    ];
    sessionVariables.EDITOR = "lvim";
    sessionVariables.VISUAL = "lvim";
    sessionVariables.BROWSER = "firefox";
    sessionVariables.TERMINAL = "kitty";
    sessionVariables.FILE_MANAGER = "thunar";
  };
}
