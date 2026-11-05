"""Real Traefik + pinned upstream auth; isolated ForwardAuth fixture, not Authelia.

Uses the evaluated production middleware chain, with ephemeral HTTP ports instead
of production TLS/Authelia. Verifies the actual raw backend peer and identity gate.
The separate VM check covers kernel UID filtering of direct local connections.
"""

import contextlib
import io
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from types import SimpleNamespace
import urllib.error
import urllib.request


source = Path(sys.argv[1])
config = json.loads(Path(sys.argv[2]).read_text())
sys.path.insert(0, str(source))

with tempfile.TemporaryDirectory(dir=os.environ["TMPDIR"]) as temp:
    os.environ.update({
        "HERMES_HOME": temp,
        "HERMES_WEBUI_STATE_DIR": temp,
        "HERMES_WEBUI_AGENT_DIR": str(Path(temp) / "no-agent"),
        "HERMES_WEBUI_AUTO_INSTALL": "0",
        "HERMES_WEBUI_TRUSTED_AUTH_HEADER": "Remote-User",
        "HERMES_WEBUI_TRUSTED_PROXY_CIDRS": "127.0.0.1/32",
    })
    from api import auth

    peers = []
    auth_requests = []

    class QuietHandler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass

    class ForwardAuthFixture(QuietHandler):
        def do_GET(self):
            auth_requests.append(dict(self.headers))
            assert self.path == "/api/authz/forward-auth"
            assert not self.headers.get("Remote-User"), "client identity reached ForwardAuth"
            assert not self.headers.get("Remote-Groups"), "client groups reached ForwardAuth"
            if self.headers.get("Cookie") != "sso-fixture=authorized":
                self.send_error(401)
                return
            self.send_response(200)
            self.send_header("Remote-User", "fixture-admin")
            self.send_header("Remote-Groups", "admin")
            self.end_headers()

    class Backend(QuietHandler):
        def do_GET(self):
            peers.append(self.client_address[0])
            if not auth.check_auth(self, SimpleNamespace(path="/api/sessions", query="")):
                return
            info = auth.ensure_trusted_auth_session(self)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(info["username"].encode())

    # Exercise the pinned implementation's raw-peer check, without trusting XFF.
    class Untrusted:
        client_address = ("192.0.2.123", 12345)
        headers = {"Remote-User": "forged", "X-Forwarded-For": "127.0.0.1"}
        wfile = io.BytesIO()
        command = "GET"
        request = SimpleNamespace()
        status = None
        def send_response(self, status):
            self.status = status
        def send_header(self, *args):
            pass
        def end_headers(self):
            pass

    untrusted = Untrusted()
    assert not auth.check_auth(untrusted, SimpleNamespace(path="/api/sessions", query=""))
    assert untrusted.status == 401

    with contextlib.ExitStack() as stack:
        backend = stack.enter_context(ThreadingHTTPServer(("127.0.0.1", 0), Backend))
        forward = stack.enter_context(ThreadingHTTPServer(("127.0.0.1", 0), ForwardAuthFixture))
        for server in [backend, forward]:
            threading.Thread(target=server.serve_forever, daemon=True).start()
            stack.callback(server.shutdown)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        router = config["router"]
        router.pop("tls")
        router["entryPoints"] = ["test"]
        # Keep the production Host rule and middleware order.
        sso = config["sso"]
        sso["forwardAuth"]["address"] = f"http://127.0.0.1:{forward.server_port}/api/authz/forward-auth"
        dynamic = {"http": {
            "routers": {"hermes-webui": router},
            "services": {"hermes-webui": {"loadBalancer": {"servers": [{"url": f"http://127.0.0.1:{backend.server_port}"}]}}},
            "middlewares": {
                "SSO": sso,
                "hermes-webui-strip-identity": config["strip"],
                "googlenoindex": {"headers": {"customResponseHeaders": {"X-Robots-Tag": "noindex"}}},
            },
        }}
        # JSON is valid YAML; Traefik selects its decoder by file extension.
        path = Path(temp) / "dynamic.yaml"
        path.write_text(json.dumps(dynamic))
        host = router["rule"].split("`")[1]
        with (Path(temp) / "traefik.log").open("w+") as log:
            process = subprocess.Popen([
                "traefik", f"--entrypoints.test.address=127.0.0.1:{port}",
                f"--providers.file.filename={path}", "--global.checknewversion=false",
                "--global.sendanonymoususage=false",
            ], stdout=log, stderr=subprocess.STDOUT)
            try:
                def request(headers):
                    req = urllib.request.Request(f"http://127.0.0.1:{port}/api/sessions", headers={"Host": host, **headers})
                    try:
                        with urllib.request.urlopen(req, timeout=5) as response:
                            return response.status, response.read()
                    except urllib.error.HTTPError as exc:
                        return exc.code, exc.read()

                deadline = time.monotonic() + 30
                while True:
                    try:
                        status, _ = request({})
                        if status == 401:
                            break
                    except urllib.error.URLError:
                        pass
                    assert process.poll() is None, "Traefik exited"
                    assert time.monotonic() < deadline, "Traefik did not become ready"
                    time.sleep(0.1)
                assert not peers, "unauthenticated request reached backend"
                assert request({"Remote-User": "forged", "Remote-Groups": "admin"})[0] == 401
                assert not peers, "forged identity bypassed ForwardAuth"
                assert request({"Cookie": "sso-fixture=authorized", "Remote-User": "forged", "Remote-Groups": "forged"}) == (200, b"fixture-admin")
                assert peers == ["127.0.0.1"], peers
                assert auth_requests
                # A trusted peer without an identity still cannot authenticate.
                try:
                    urllib.request.urlopen(f"http://127.0.0.1:{backend.server_port}/api/sessions", timeout=5)
                    raise AssertionError("missing identity was accepted")
                except urllib.error.HTTPError as exc:
                    assert exc.code == 401
                print("SSO: real Traefik peer=127.0.0.1; forged identity stripped; anonymous denied; fixture identity accepted; untrusted raw peer denied")
            finally:
                process.terminate()
                process.wait(timeout=15)
                log.seek(0)
                print(log.read())
