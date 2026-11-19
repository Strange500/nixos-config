"""Smoke-test a staged, real release. No live server or user data is used."""
import http.client
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import tempfile
import time

node, release = sys.argv[1:]
release = Path(release).resolve()
subprocess.run(["sha256sum", "--check", "--status", "SHA256SUMS"], cwd=release, check=True)
with tempfile.TemporaryDirectory(prefix="tempo-smoke-") as data:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    password = secrets.token_urlsafe(32)  # ephemeral test-only, never printed
    env = dict(os.environ, NODE_ENV="production", HOST="127.0.0.1", PORT=str(port),
               APP_ORIGIN="https://edt.qgroget.com", DATA_DIR=data, APP_PASSWORD=password)

    def request(path, method="GET", body=None, cookie=None, origin="https://edt.qgroget.com"):
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=2)
        headers = {"X-Tempo": "1", "Origin": origin, "Content-Type": "application/json"}
        if cookie:
            headers["Cookie"] = cookie
        connection.request(method, path, None if body is None else json.dumps(body), headers)
        response = connection.getresponse()
        result = response.status, dict(response.getheaders()), response.read()
        connection.close()
        return result

    def start():
        process = subprocess.Popen([node, "server/index.js"], cwd=release, env=env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            try:
                assert request("/api/health")[0] == 200
                return process
            except OSError:
                if process.poll() is not None:
                    raise RuntimeError("Production server exited before becoming healthy")
                time.sleep(0.05)
        process.terminate()
        process.wait(timeout=5)
        raise RuntimeError("Production health timeout")

    def login():
        status, headers, _ = request("/api/login", "POST", {"password": password})
        assert status == 200
        cookie = headers["Set-Cookie"]
        assert all(flag in cookie for flag in ["Secure", "HttpOnly", "SameSite=Strict"])
        return cookie.split(";")[0]

    missing_password = dict(env)
    missing_password.pop("APP_PASSWORD")
    refused = subprocess.run([node, "server/index.js"], cwd=release, env=missing_password,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
    assert refused.returncode != 0, "Production must refuse a missing password"
    process = start()
    try:
        assert request("/")[0] == 200
        assert request("/api/state")[0] == 401
        assert request("/api/login", "POST", {"password": password}, origin="https://invalid.example")[0] == 403
        cookie = login()
        state = json.loads(request("/api/state", cookie=cookie)[2])
        state["tasks"] = [{"id": "infra-smoke", "title": "Synthetic deployment smoke",
                           "date": "2026-11-19", "done": False}]
        assert request("/api/state", "PUT", state, cookie)[0] == 200
        process.terminate()
        assert process.wait(timeout=5) == 0
        process = start()
        assert request("/api/state", cookie=cookie)[0] == 401  # restart invalidates sessions
        cookie = login()
        restored = json.loads(request("/api/state", cookie=cookie)[2])
        assert restored["tasks"][0]["id"] == "infra-smoke"
        assert Path(data, "tempo.sqlite").stat().st_mode & 0o777 == 0o600
        print("PASS: built assets, health, auth/CSRF, Secure cookie, restart, SQLite persistence and permissions")
    finally:
        process.terminate()
        process.wait(timeout=5)
