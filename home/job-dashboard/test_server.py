"""HTTP regression tests; persistence is isolated from production data."""
import json
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.request import Request, urlopen

import server


class DashboardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.old_data_file = server.DATA_FILE
        server.DATA_FILE = str(Path(self.tmp.name) / "data.json")
        self.httpd = server.ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.thread.start()
        self.base = f"http://127.0.0.1:{self.httpd.server_port}"

    def tearDown(self):
        self.httpd.shutdown()
        self.httpd.server_close()
        self.thread.join()
        server.DATA_FILE = self.old_data_file
        self.tmp.cleanup()

    def request(self, path, method="GET", body=None):
        data = json.dumps(body).encode() if body is not None else None
        with urlopen(Request(self.base + path, data=data, method=method,
                             headers={"Content-Type": "application/json"})) as response:
            return json.load(response)

    def create(self, **fields):
        return self.request("/api/jobs", "POST", {
            "company": "Example", "title": "Rust intern", "notes": "Keep me",
            **fields,
        })

    def test_select_persist_return_and_apply(self):
        selected = self.create()
        other = self.create(company="Other")
        path = "/api/jobs/" + selected["id"]
        moved = self.request(path, "PATCH", {"status": "triage"})
        self.assertEqual(moved["status"], "triage")
        self.assertEqual(moved["id"], selected["id"])
        self.assertEqual(moved["notes"], "Keep me")
        self.assertEqual(moved["match"], selected["match"])
        persisted = json.loads(Path(server.DATA_FILE).read_text())["jobs"]
        self.assertEqual(next(j for j in persisted if j["id"] == selected["id"])["status"], "triage")
        self.assertEqual(next(j for j in self.request("/api/jobs") if j["id"] == other["id"])["status"], "backlog")
        stats = self.request("/api/stats")
        self.assertEqual((stats["total"], stats["backlog"], stats["triage"]), (2, 1, 1))
        self.assertEqual(sum(stats[s] for s in server.STATUSES), stats["total"])
        self.assertEqual(self.request(path, "PATCH", {"status": "backlog"})["status"], "backlog")
        self.request(path, "PATCH", {"status": "triage"})
        self.assertEqual(self.request(path, "PATCH", {"status": "applied"})["status"], "applied")

    def test_create_edit_sort_and_delete_triage(self):
        job = self.create(status="triage")
        self.assertEqual(job["status"], "triage")
        path = "/api/jobs/" + job["id"]
        self.assertEqual(self.request(path, "PATCH", {"notes": "Edited"})["status"], "triage")
        for sort in ("match", "added"):
            self.assertEqual(self.request("/api/jobs?sort=" + sort)[0]["status"], "triage")
        self.request(path, "DELETE")
        self.assertEqual(self.request("/api/stats")["triage"], 0)

    def test_existing_data_requires_no_migration(self):
        server.save_data({"jobs": [{"id": "legacy", "status": "backlog", "company": "Legacy"}]})
        self.assertEqual(self.request("/api/jobs")[0]["status"], "backlog")
        self.assertEqual(self.request("/api/stats")["triage"], 0)
        self.assertEqual(self.create(status="invalid")["status"], "backlog")


if __name__ == "__main__":
    unittest.main()
