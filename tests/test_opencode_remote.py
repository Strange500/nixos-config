"""Offline checks: no production endpoint or real credential is used."""
import importlib.util
import json
import os
from pathlib import Path
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("remote", ROOT / "scripts/opencode-remote.py")
assert SPEC is not None and SPEC.loader is not None
remote = importlib.util.module_from_spec(SPEC)


class RemoteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        assert SPEC is not None and SPEC.loader is not None
        SPEC.loader.exec_module(remote)

    def env(self, url="http://127.0.0.1:18642/v1"):
        return {"HERMES_API_BASE_URL": url, "HERMES_API_KEY": "fixture-only"}

    def test_defaults(self):
        env = remote.prepare_environment(self.env())
        self.assertEqual(env["HERMES_MODEL_ID"], "hermes-agent")
        config = json.loads(env["OPENCODE_CONFIG_CONTENT"])
        self.assertEqual(config["model"], "hermes/hermes-agent")
        self.assertEqual(config["small_model"], config["model"])
        self.assertEqual(config["permission"], {"*": "deny"})
        self.assertEqual(config["enabled_providers"], ["hermes"])
        self.assertFalse(config["provider"]["hermes"]["models"]["hermes-agent"]["tool_call"])
        self.assertNotIn("fixture-only", env["OPENCODE_CONFIG_CONTENT"])

    def test_missing_values(self):
        for env in ({}, {"HERMES_API_BASE_URL": "https://example.invalid/v1"}):
            with self.subTest(env=env), self.assertRaises(ValueError):
                remote.prepare_environment(env)

    def test_https_and_loopback(self):
        for url in ("https://example.invalid/v1", "http://localhost:8642/v1", "http://[::1]:8642/v1"):
            with self.subTest(url=url):
                remote.prepare_environment(self.env(url))

    def test_reject_unsafe_urls(self):
        for url in ("http://example.invalid/v1", "ftp://localhost/v1", "https://user:pass@example.invalid/v1", "https://@example.invalid/v1", "https://example.invalid /v1", "https://example.invalid/v1?key=x", "https://example.invalid/v1#x", "https://example.invalid", "https://example.invalid/v1\n", "https://example.invalid:bad/v1"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                remote.prepare_environment(self.env(url))

    def test_reject_header_injection(self):
        env = self.env()
        env["HERMES_API_KEY"] = "fixture\r\nInjected: yes"
        with self.assertRaises(ValueError):
            remote.prepare_environment(env)

    def test_named_profile_model(self):
        env = self.env()
        env["HERMES_MODEL_ID"] = "staging"
        self.assertEqual(remote.prepare_environment(env)["HERMES_MODEL_ID"], "staging")

    def test_preflight_contract(self):
        requests = []
        status = [200]
        payload: list[dict] = [{"data": [{"id": "hermes-agent"}]}]

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append((self.path, self.headers.get("Authorization")))
                self.send_response(status[0])
                if status[0] == 302:
                    self.send_header("Location", "/credential-trap")
                self.end_headers()
                self.wfile.write(json.dumps(payload[0]).encode())

            def log_message(self, format, *args):
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            env = remote.prepare_environment(self.env(f"http://127.0.0.1:{server.server_port}/v1"))
            remote.check_models(env)
            self.assertEqual(requests, [("/v1/models", "Bearer fixture-only")])
            payload[0] = {"data": [{"id": "other-profile"}]}
            with self.assertRaises(ValueError):
                remote.check_models(env)
            payload[0] = {"data": None}
            with self.assertRaises(ValueError):
                remote.check_models(env)
            for code in (401, 403, 302):
                status[0] = code
                before = len(requests)
                with self.assertRaises(ValueError) as caught:
                    remote.check_models(env)
                self.assertNotIn("fixture-only", str(caught.exception))
                self.assertEqual(len(requests), before + 1)
        finally:
            server.shutdown()
            server.server_close()
            thread.join()

    def test_main_fails_closed_without_credentials(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(remote.main(["--check"]), 2)


if __name__ == "__main__":
    unittest.main()
