"""Smoke-test the pinned WebUI offline, without real Hermes state or API keys."""

import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request


source = Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix="hermes-webui-", dir=os.environ["TMPDIR"]) as temp:
    home = Path(temp)
    # A deterministic fixture, not a real credential: verify the shared Agent
    # home's dotenv is used without putting gateway secrets in the Nix store.
    (home / ".env").write_text("API_SERVER_KEY=hermes-webui-test-fixture-only\n")
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
        "HERMES_WEBUI_GATEWAY_BASE_URL": "http://127.0.0.1:8642",
        "HERMES_WEBUI_GATEWAY_USE_RUNS_API": "true",
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
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/api/health/agent", timeout=15) as response:
                assert response.status == 200
                gateway = json.load(response)["gateway_chat"]
                assert gateway["enabled"] and gateway["backend"] == "gateway"
                assert gateway["base_url_configured"] and gateway["api_key_configured"]
            assert (home / "webui").is_dir(), "WebUI state must stay outside the read-only source"
            print("Hermes WebUI: HTTP 200 on health/index/agent health; gateway backend and dotenv key configured")
        finally:
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            log.seek(0)
            print(log.read())
