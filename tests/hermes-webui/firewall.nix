{
  pkgs,
  serverConfig,
}:
pkgs.testers.runNixOSTest {
  name = "hermes-webui-proxy-uid";
  nodes.machine = {pkgs, ...}: {
    users.users.traefik = {
      isSystemUser = true;
      group = "traefik";
    };
    users.groups.traefik = {};
    networking.firewall = {
      enable = true;
      # Exercise the exact evaluated host rules, not a copied approximation.
      inherit (serverConfig.networking.firewall) extraCommands extraStopCommands;
    };
    environment.systemPackages = [pkgs.curl];
    systemd.services.backend = {
      wantedBy = ["multi-user.target"];
      after = ["firewall.service"];
      requires = ["firewall.service"];
      partOf = ["firewall.service"];
      serviceConfig.ExecStart = "${pkgs.python3}/bin/python -m http.server 8787 --bind 127.0.0.1";
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("backend.service")
    machine.wait_until_succeeds("su -s /bin/sh traefik -c 'curl --fail --max-time 3 http://127.0.0.1:8787/'")
    machine.fail("su -s /bin/sh nobody -c 'curl --fail --max-time 3 -H Remote-User:forged http://127.0.0.1:8787/'")
    machine.fail("curl --fail --max-time 3 -H Remote-User:forged http://127.0.0.1:8787/")
    machine.succeed("systemctl restart firewall.service")
    machine.succeed("su -s /bin/sh traefik -c 'curl --fail --max-time 3 http://127.0.0.1:8787/'")
    machine.fail("su -s /bin/sh nobody -c 'curl --fail --max-time 3 -H Remote-User:forged http://127.0.0.1:8787/'")
  '';
}
