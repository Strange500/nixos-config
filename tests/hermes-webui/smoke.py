"""Smoke-test the pinned WebUI offline, without real Hermes state or API keys."""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request


source = Path(sys.argv[1])
fixture_key = "hermes-webui-test-fixture-only"


class GatewayFixture(BaseHTTPRequestHandler):
    """Offline gateway fixture, not an Agent or an LLM response."""

    def do_GET(self):
        if self.path != "/health/detailed":
            self.send_error(404)
            return
        if self.headers.get("Authorization") != f"Bearer {fixture_key}":
            self.send_error(401)
            return
        body = json.dumps({"gateway_state": "running"}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass


with (
    tempfile.TemporaryDirectory(prefix="hermes-webui-", dir=os.environ["TMPDIR"]) as temp,
    ThreadingHTTPServer((sys.argv[2], 0), GatewayFixture) as gateway_server,
):
    gateway_thread = threading.Thread(target=gateway_server.serve_forever, daemon=True)
    gateway_thread.start()
    # A different local destination models forwarding to the pod's interface:
    # binding only 127.0.0.1 must NOT pass. No real pod, Agent or secrets are used.
    gateway_url = f"http://127.0.0.2:{gateway_server.server_port}"
    home = Path(temp)
    # A deterministic fixture, not a real credential: verify the shared Agent
    # home's dotenv is used without putting gateway secrets in the Nix store.
    (home / ".env").write_text(f"API_SERVER_KEY={fixture_key}\n")
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    env = {
        "PATH": os.environ["PATH"],
        "HOME": str(home),
        "TMPDIR": str(home),
        "HERMES_HOME": str(home),
        # Browser-only mode: exercise HTTP without installing an Agent or
        # importing a developer's real Agent, profiles, credentials or config.
        "HERMES_WEBUI_AGENT_DIR": str(home / "no-agent"),
        "HERMES_WEBUI_STATE_DIR": str(home / "webui"),
        "HERMES_WEBUI_HOST": "127.0.0.1",
        "HERMES_WEBUI_PORT": str(port),
        "HERMES_WEBUI_AUTO_INSTALL": "0",
        "HERMES_WEBUI_CHAT_BACKEND": "gateway",
        "HERMES_WEBUI_GATEWAY_BASE_URL": gateway_url,
        "HERMES_WEBUI_GATEWAY_USE_RUNS_API": "true",
        "HERMES_WEBUI_TRUSTED_AUTH_HEADER": "Remote-User",
        "HERMES_WEBUI_TRUSTED_PROXY_CIDRS": "127.0.0.1/32",
        "PYTHONDONTWRITEBYTECODE": "1",
    }
    with (home / "server.log").open("w+") as log:
        process = subprocess.Popen(
            [sys.executable, str(source / "server.py")],
            cwd=home,
            env=env,
            stdout=log,
            stderr=subprocess.STDOUT,
        )
        try:
            deadline = time.monotonic() + 90
            while True:
                if process.poll() is not None:
                    raise RuntimeError(f"WebUI exited with {process.returncode}")
                try:
                    with urllib.request.urlopen(f"http://127.0.0.1:{port}/health", timeout=3) as response:
                        assert response.status == 200
                        assert json.load(response)["status"] == "ok"
                    break
                except (urllib.error.URLError, TimeoutError):
                    if time.monotonic() >= deadline:
                        raise RuntimeError("WebUI did not become healthy")
                    time.sleep(0.25)
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/", timeout=5) as response:
                assert response.status == 200
                assert b"<html" in response.read().lower()
            api_url = f"http://127.0.0.1:{port}/api/health/agent"
            try:
                urllib.request.urlopen(api_url, timeout=5)
                raise AssertionError("API accepted a missing SSO identity")
            except urllib.error.HTTPError as exc:
                assert exc.code == 401
            request = urllib.request.Request(api_url, headers={"Remote-User": "fixture-admin"})
            with urllib.request.urlopen(request, timeout=15) as response:
                assert response.status == 200
                health = json.load(response)
                assert health["alive"], health
                assert health["details"]["reason"] == "remote_gateway", health
                assert health["details"]["endpoint"] == gateway_url + "/health/detailed", health
                assert health["details"]["gateway_state"] == "running", health
                gateway = health["gateway_chat"]
                assert gateway["enabled"] and gateway["backend"] == "gateway"
                assert gateway["base_url_configured"] and gateway["api_key_configured"]
            assert (home / "webui").is_dir(), "WebUI state must stay outside the read-only source"
            print("Hermes WebUI: HTTP 200 on health/index; authenticated gateway probe alive across distinct loopback addresses")
        finally:
            gateway_server.shutdown()
            gateway_thread.join(timeout=5)
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            log.seek(0)
            print(log.read())
