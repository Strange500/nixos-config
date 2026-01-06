{
  pkgs,
  lib,
  config,
  ...
}: {
  home = lib.mkIf config.qgroget.nixos.apps.basic {
    packages = with pkgs; [
      unzip
      unrar
      zip
      git
      telegram-desktop
    ];
  };
}
