{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = lib.mkIf config.qgroget.nixos.apps.crypto (with pkgs; [
    ledger-live-desktop
    trezor-suite
  ]);
}
