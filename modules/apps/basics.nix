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
      telegram-desktop
    ];
    sessionVariables.EDITOR = "code --wait --skip-welcome --skip-release-notes --disable-telemetry --skip-add-to-recently-opened";
    sessionVariables.VISUAL = "code --wait --skip-welcome --skip-release-notes --disable-telemetry --skip-add-to-recently-opened";
    sessionVariables.BROWSER = "firefox";
    sessionVariables.TERMINAL = "kitty";
    sessionVariables.FILE_MANAGER = "thunar";
  };
}
