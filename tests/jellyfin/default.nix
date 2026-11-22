{
  pkgs,
  jellarr,
  ...
}:
pkgs.testers.nixosTest {
  name = "jellyfin-jellarr-test";

  nodes.server = {lib, ...}: {
    imports = [
      ../../settings.nix
      ../../modules/server/options.nix
      ../../modules/server/media/video
      ../lib/sops-mock.nix
      jellarr.nixosModules.default
    ];
    options.qgroget.backups = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
    options.qgroget.server.domain = lib.mkOption {
      type = lib.types.str;
      default = "example.test";
    };
    config = {
      virtualisation.diskSize = 4096;
      users.groups.media = {};
      users.groups.music = {};
      qgroget.server.jellyfin.enable = true;
      # Keep the actual Jellyfin server in this regression test. Exercise the
      # packaged reconciler against a deterministic REST fixture separately.
      systemd.services.jellarr.wantedBy = lib.mkForce [];
      systemd.timers.jellarr.wantedBy = lib.mkForce [];
      environment.systemPackages = [pkgs.python3];
    };
  };

  testScript = ''
    import json
    import shlex

    start_all()
    server.wait_for_unit("jellyfin.service")
    server.wait_for_open_port(8096)
    server.wait_until_succeeds("curl -f http://localhost:8096/health", timeout=180)
    server.succeed("test -f /etc/systemd/system/jellarr.service")
    server.succeed("test ! -e /etc/systemd/system/jellarr-api-key-bootstrap.service")

    # Use the real generated config, unit and binary, but redirect its loopback
    # endpoint to a mock. Never use credentials from production in a VM.
    fixture = r"""
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import json
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args): pass
        def do_GET(self):
            if self.path == '/System/Info/Public':
                body = {}
            elif self.path == '/System/Configuration':
                assert self.headers.get('X-Emby-Token') == 'fake-test-value'
                body = {'EnableMetrics': True, 'ServerName': 'keep-existing'}
            else:
                assert self.headers.get('X-Emby-Token') == 'fake-test-value'
                assert self.path == '/System/Configuration/Branding', self.path
                body = getattr(self.server, 'branding', {'LoginDisclaimer': 'before', 'CustomCss': 'before', 'SplashscreenEnabled': False})
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(body).encode())
        def do_POST(self):
            assert self.headers.get('X-Emby-Token') == 'fake-test-value'
            assert self.path == '/System/Configuration/Branding', self.path
            data = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
            self.server.branding = data
            with open('/tmp/jellarr-applied.json', 'w') as f: json.dump(data, f)
            self.send_response(204)
            self.end_headers()
    HTTPServer(('127.0.0.1', 8096), Handler).serve_forever()
    """
    server.succeed("systemctl stop jellyfin.service")
    server.succeed("printf %s " + shlex.quote(fixture) + " > /tmp/jellarr-fixture.py")
    server.succeed("systemd-run --unit=jellarr-fixture python /tmp/jellarr-fixture.py")
    server.wait_for_open_port(8096)
    # Prevent Wants=jellyfin.service from starting the real server again.
    server.succeed("systemctl mask --runtime jellyfin.service")
    server.succeed("systemctl start jellarr.service")
    applied = json.loads(server.succeed("cat /tmp/jellarr-applied.json"))
    assert applied == {"LoginDisclaimer": "", "CustomCss": "", "SplashscreenEnabled": True}, applied
    server.succeed("systemctl start jellarr.service")
    server.succeed("systemctl is-active jellarr-fixture.service")
    print("Jellyfin health and real Jellarr reconciliation passed")
  '';
}
