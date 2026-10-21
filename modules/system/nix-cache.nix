{config, lib, ...}: let
  cfg = config.qgroget.nix-cache;

  # Public half of the harmonia signing key. The private half lives in
  # secrets/nix-cache.yaml (sops-encrypted, referenced by the Server module).
  # Regenerate both together if the key ever needs rotating:
  #   nix-store --generate-binary-cache-key cache.qgroget.com-1 /tmp/sec /tmp/pub
  #   cat /tmp/pub   # -> paste the "<name>:<base64>" string below
  cachePublicKey = "cache.qgroget.com-1:A6LC4w+9pB9shJzekUa5mpTqwEy9/pLuws9gkneIkLE=";
in {
  config = lib.mkIf cfg.enable {
    # Plain HTTP over the tailnet (WireGuard already encrypts); harmonia
    # + cache.nixos.org are queried together and nix falls back on cache miss.
    nix.settings.substituters = [
      "http://${cfg.host}:${toString cfg.port}"
    ];

    # NixOS list options concatenate across module definitions, so this merges
    # with the keys declared in modules/system/nix.nix.
    nix.settings.trusted-public-keys = [
      cachePublicKey
    ];
  };
}