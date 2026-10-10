#!/usr/bin/env python3
"""Job Dashboard — self-contained server (Python stdlib only).

Serves a single-page candidate-tracking dashboard plus a small JSON REST API.
Persistence: data.json next to this script (lives under /home/hermes which is
on the persisted ZFS pool, so it survives reboots).

Endpoints:
  GET  /                    -> the dashboard (index.html)
  GET  /api/jobs            -> list all applications
  POST /api/jobs            -> create one   (JSON body)
  PATCH /api/jobs/<id>      -> update one
  DELETE /api/jobs/<id>     -> delete one
"""
import json
import os
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, "data.json")
INDEX_FILE = os.path.join(BASE_DIR, "index.html")
HOST = os.environ.get("HOSTNAME", "127.0.0.1")
PORT = int(os.environ.get("PORT", "3003"))
_lock = threading.Lock()

STATUSES = ["backlog", "applied", "interview", "offer", "rejected"]
VALID_KEYS = {"company", "title", "location", "url", "status", "deadline",
              "notes", "source", "salary", "added_at", "updated_at"}


def load_data():
    if not os.path.exists(DATA_FILE):
        return {"jobs": []}
    with open(DATA_FILE, encoding="utf-8") as fh:
        return json.load(fh)


def save_data(data):
    with _lock:
        tmp = DATA_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False, indent=2)
        os.replace(tmp, DATA_FILE)


def clean_job(job, job_id=None):
    """Keep only known keys + sane defaults."""
    clean = {k: v for k, v in job.items() if k in VALID_KEYS and v is not None}
    clean["status"] = clean.get("status", "backlog")
    if clean["status"] not in STATUSES:
        clean["status"] = "backlog"
    for f in ("company", "title", "location", "location") :
        clean.setdefault(f, "")
    clean.setdefault("url", "")
    clean.setdefault("deadline", "")
    clean.setdefault("notes", "")
    clean.setdefault("source", "")
    clean.setdefault("salary", "")
    clean["id"] = job_id if job_id is not None else str(hash(json.dumps(clean, sort_keys=True)) & 0xFFFFFFFF)
    return clean


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype + ("; charset=utf-8" if ctype.startswith("application/json") else ""))
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length <= 0:
            return {}
        try:
            return json.loads(self.rfile.read(length))
        except Exception:
            return {}

    def log_message(self, *args):
        pass

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/" or parsed.path == "/index.html":
            try:
                with open(INDEX_FILE, "rb") as fh:
                    self._send(200, fh.read(), "text/html")
            except FileNotFoundError:
                self._send(500, {"error": "index.html missing"})
            return
        if parsed.path == "/api/jobs":
            data = load_data()
            self._send(200, data["jobs"])
            return
        if parsed.path == "/api/stats":
            jobs = load_data()["jobs"]
            stats = {s: sum(1 for j in jobs if j.get("status") == s) for s in STATUSES}
            stats["total"] = len(jobs)
            self._send(200, stats)
            return
        self._send(404, {"error": "not found"})

    def do_POST(self):
        if urlparse(self.path).path == "/api/jobs":
            body = self._read_body()
            data = load_data()
            job = clean_job(body)
            job["added_at"] = job.get("added_at", "")
            data["jobs"].insert(0, job)
            save_data(data)
            self._send(201, job)
            return
        self._send(404, {"error": "not found"})

    def do_PATCH(self):
        m = re.match(r"^/api/jobs/([^/]+)$", urlparse(self.path).path)
        if not m:
            self._send(404, {"error": "not found"})
            return
        job_id = m.group(1)
        body = self._read_body()
        data = load_data()
        for job in data["jobs"]:
            if str(job.get("id")) == job_id:
                merged = {**job, **body}
                job.clear()
                job.update(clean_job(merged, job_id=job_id))
                job["updated_at"] = body.get("updated_at", "")
                save_data(data)
                self._send(200, job)
                return
        self._send(404, {"error": "no such job"})

    def do_DELETE(self):
        m = re.match(r"^/api/jobs/([^/]+)$", urlparse(self.path).path)
        if not m:
            self._send(404, {"error": "not found"})
            return
        job_id = m.group(1)
        data = load_data()
        before = len(data["jobs"])
        data["jobs"] = [j for j in data["jobs"] if str(j.get("id")) != job_id]
        if len(data["jobs"]) == before:
            self._send(404, {"error": "no such job"})
            return
        save_data(data)
        self._send(200, {"ok": True})


def main():
    if not os.path.exists(DATA_FILE):
        save_data({"jobs": []})
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"job-dashboard listening on http://{HOST}:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()