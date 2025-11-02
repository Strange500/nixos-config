{config, ...}: {
  environment.persistence."/persist".directories = [
    "/etc/nix-bitcoin-secrets"
  ];

  # tmp files to ensure required directories exist
  systemd.tmpfiles.rules = [
    "Z /etc/nix-bitcoin-secrets 0700 bitcoin bitcoin -"
    "Z ${config.services.bitcoind.dataDir} 0700 bitcoin bitcoin -"
  ];

  # Automatically generate all secrets required by services.
  # The secrets are stored in /etc/nix-bitcoin-secrets
  nix-bitcoin.generateSecrets = true;

  # Enable some services.
  # See ../configuration.nix for all available features.
  services.bitcoind = {
    enable = true;
    dataDir = "/mnt/crypto/bitcoin";
  };
  #services.clightning.enable = true;

  users.users.btc = {
    isNormalUser = true;
    home = "/nonexistent";
    description = "Bitcoin User";
    createHome = false;
  };

  nix-bitcoin.operator = {
    enable = true;
    name = "btc";
  };
}
