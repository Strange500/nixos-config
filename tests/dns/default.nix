{pkgs, ...}:
pkgs.testers.nixosTest {
  name = "dns-test";

  nodes = {
    server = {...}: {
      imports = [
        ../../settings.nix
        ../../modules/server/options.nix
        ../../modules/server/dns
      ];

      config = {
        # AdGuard Home bind_hosts hardcodes qgroget.server.network.ip
        # (192.168.0.28 on prod), an address that does not exist inside the
        # VM — AdGuardHome would die with "bind: cannot assign requested
        # address" on 192.168.0.28.
        #
        # nixosTest hands out 192.168.1.<n> in ALPHABETICAL order of node
        # name, starting at 1. `server` is the only node, so it owns .1 —
        # keep this in sync if a node sorting before "server" is ever added.
        qgroget.server.network.ip = "192.168.1.1";
      };
    };
  };

  testScript = ''
    start_all()

    # AdGuard Home dashboard (mutableSettings=false -> declarative yaml, no
    # bootstrap wizard). Poll: AdGuard takes a moment to apply filters/config.
    server.wait_for_unit("adguardhome.service")
    server.wait_for_open_port(3000)
    server.wait_until_succeeds("curl -f http://127.0.0.1:3000", timeout=60)

    # Unbound recursive resolver listening on 127.0.0.1:5335 (TCP).
    server.wait_for_unit("unbound.service")
    server.wait_for_open_port(5335)

    print("All DNS tests passed!")
  '';
}