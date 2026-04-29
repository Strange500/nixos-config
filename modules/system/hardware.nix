{config, ...}: {
  hardware = {
    graphics.enable = true;
    ledger.enable = config.qgroget.nixos.apps.crypto;
  };

  services.trezord.enable = config.qgroget.nixos.apps.crypto;
}
