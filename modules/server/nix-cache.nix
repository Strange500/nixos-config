{config, lib, ...}: let
  cfg = config.qgroget.server.nix-cache;
in {
  config = lib.mkIf cfg.enable {
    # Signing key (private half). Public half + client config live in
    # modules/system/nix-cache.nix. LoadCredential in the harmonia module reads
    # it as root, so the default root:root 0600 sops perms are sufficient at
    # /run/secrets/server/nix-cache/signing-key.
    sops.secrets."server/nix-cache/signing-key" = {
      sopsFile = ../../secrets/nix-cache.yaml;
    };

    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [
        config.sops.secrets."server/nix-cache/signing-key".path
      ];

      settings = {
        # Default is already "[::]:5000" (all interfaces). Kept explicit:
        # reachable on the LAN and, once Tailscale is up, the tailnet
        # interface. Access is gated by the firewall below and Tailscale ACLs.
        bind = "[::]:5000";
      };
    };

    # Open harmonia to the LAN + tailnet. The Server sits behind NAT (no public
    # IP), so this does not expose the cache to the internet.
    networking.firewall.allowedTCPPorts = [5000];
  };
}