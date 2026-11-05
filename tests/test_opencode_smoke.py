"""Real OpenCode binary against an explicitly synthetic loopback SSE fixture."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.environ.get("OPENCODE_BIN"), "Set OPENCODE_BIN to run the real CLI smoke test")
class OpenCodeSmoke(unittest.TestCase):
    def test_real_cli_chat_stream(self):
        self.run_fixture(include_progress=False)

    def test_real_cli_rejects_custom_progress(self):
        self.run_fixture(include_progress=True)

    def run_fixture(self, include_progress):
        requests = []

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append((self.path, self.headers.get("Authorization"), None))
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"data":[{"id":"staging"}]}')

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                requests.append((self.path, self.headers.get("Authorization"), body))
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.end_headers()
                self.wfile.write(b': keepalive\n\n')
                if include_progress:
                    self.wfile.write(b'event: hermes.tool.progress\ndata: {"tool":"fixture","status":"completed"}\n\n')
                for delta, reason in (({"role": "assistant", "content": "SYNTHETIC_SSE_FIXTURE_OK"}, None), ({}, "stop")):
                    chunk = {"id": "chatcmpl-fixture", "object": "chat.completion.chunk", "created": 1, "model": "staging", "choices": [{"index": 0, "delta": delta, "finish_reason": reason}]}
                    self.wfile.write(("data: " + json.dumps(chunk) + "\n\n").encode())
                self.wfile.write(b'data: [DONE]\n\n')

            def log_message(self, format, *args):
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory(prefix="opencode-smoke-") as tmp:
                env = {"PATH": os.environ["PATH"], "HOME": tmp, "TMPDIR": tmp,
                       "XDG_CONFIG_HOME": tmp + "/config", "XDG_DATA_HOME": tmp + "/data",
                       "XDG_STATE_HOME": tmp + "/state", "XDG_CACHE_HOME": tmp + "/cache",
                       "OPENCODE_BIN": os.environ["OPENCODE_BIN"],
                       "HERMES_API_BASE_URL": f"http://127.0.0.1:{server.server_port}/v1",
                       "HERMES_API_KEY": "fixture-only", "HERMES_MODEL_ID": "staging"}
                result = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/opencode-remote.py"),
                                         "--workspace", tmp, "--", "run", "--format", "json",
                                         "Reply with the test fixture."],
                                        env=env, text=True, capture_output=True, timeout=120)
                if include_progress:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("Type validation failed", result.stdout + result.stderr)
                    return
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("SYNTHETIC_SSE_FIXTURE_OK", result.stdout, result.stderr)
                self.assertNotIn("fixture-only", result.stdout + result.stderr)
                completions = [r for r in requests if r[0] == "/v1/chat/completions"]
                self.assertEqual(len(completions), 1, requests)
                _, auth, body = completions[0]
                self.assertEqual(auth, "Bearer fixture-only")
                self.assertEqual(body["model"], "staging")
                self.assertTrue(body["stream"])
                self.assertFalse(body.get("tools"))
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == "__main__":
    unittest.main()
