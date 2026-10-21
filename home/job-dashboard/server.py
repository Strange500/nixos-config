#!/usr/bin/env python3
"""Job Dashboard — self-contained server (Python stdlib only).

Serves a single-page candidate-tracking dashboard plus a small JSON REST API.
Persistence: data.json next to this script (lives under /home/hermes which is
on the persisted ZFS pool, so it survives reboots).

Endpoints:
  GET  /                          -> the dashboard (index.html)
  GET  /api/jobs[?sort=match|added] -> list all applications
  GET  /api/stats                 -> counts per status
  POST /api/jobs                  -> create one (match score auto-computed)
  PATCH /api/jobs/<id>            -> update one (match score recomputed)
  DELETE /api/jobs/<id>           -> delete one

Fit scoring: each job is ranked 0-100 ("match") against Strange's target
profile (Rust-first: backend/systems/low-level/infra/cloud/DevOps-SRE/
fullstack/DB/ML), so the board can be sorted by best fit.
"""
import json
import os
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, "data.json")
INDEX_FILE = os.path.join(BASE_DIR, "index.html")
HOST = os.environ.get("HOSTNAME", "127.0.0.1")
PORT = int(os.environ.get("PORT", "3003"))
_lock = threading.Lock()

STATUSES = ["backlog", "applied", "interview", "offer", "rejected"]
VALID_KEYS = {"company", "title", "location", "url", "status", "deadline",
              "notes", "source", "salary", "contact", "added_at", "updated_at",
              "match"}

# --- Fit scoring -----------------------------------------------------------
# Strange's target profile, regex -> weight. Each group scores at most once.
PROFILE = [
    (re.compile(r"\brust\b"), 28),
    (re.compile(r"\bsystems?\b"), 12),
    (re.compile(r"\blow[- ]?level\b"), 12),
    (re.compile(r"\bback[- ]?end\b"), 12),
    (re.compile(r"\binfra(?:structure)?\b"), 10),
    (re.compile(r"\bdevops\b"), 10),
    (re.compile(r"\bsre\b|site reliability"), 10),
    (re.compile(r"\bcloud\b"), 8),
    (re.compile(r"\baws\b|\bgcp\b|\bazure\b"), 8),
    (re.compile(r"\bgo(?:lang)?\b|\bkotlin\b"), 7),
    (re.compile(r"\bfull[- ]?stack\b"), 7),
    (re.compile(r"\bjava\b|\bspring\b"), 6),
    (re.compile(r"\btypescript\b|\bangular\b|\breact\b|\bnode(?:\.js)?\b"), 6),
    (re.compile(r"\bpostgres(?:ql)?\b|\bsql\b|\bdatabase\b"), 6),
    (re.compile(r"\bdata\b|\bml\b|machine learning"), 6),
    (re.compile(r"\bnetwork(?:ing)?\b"), 5),
    (re.compile(r"\bsecurity\b|cyber"), 5),
    (re.compile(r"\bdistributed\b|\bconcurr\w*\b|\bparallel\b"), 5),
    (re.compile(r"\bgit\b|\blinux\b|\bdocker\b|\bkubernetes\b|\bk8s\b"), 5),
]

# Location hints (checked on the lowercased location string).
US_HINTS = re.compile(
    r"\b(usa|united states|california|ca\b|texas|tx\b|new york|ny\b|washington|"
    r"seattle|san francisco|sf\b|bay area|silicon valley|new jersey|nj\b|"
    r"colorado|co\b|massachusetts|boston|virginia|va\b|illinois|chicago|"
    r"north carolina|nc\b|georgia|atlanta|oregon|portland|austin|"
    r"remote in us|us remote)\b")
NON_US_HINTS = re.compile(
    r"\b(canada|toronto|uk\b|united kingdom|london|france|paris|germany|berlin|"
    r"netherlands|amsterdam|ireland|dublin|india|bangalore|israel|tel aviv|"
    r"singapore|australia|europe|remote in eu|switzerland|zurich)\b")


def _words(*fields):
    return " ".join(str(f or "") for f in fields).lower()


def score_job(job):
    """Return 0-100 fit score for a job against Strange's profile."""
    hay = _words(job.get("title"), job.get("notes"), job.get("company"),
                 job.get("location"), job.get("salary"))
    s = 20  # base: a relevant US internship
    for pat, weight in PROFILE:
        if pat.search(hay):
            s += weight
    title = _words(job.get("title"))
    if re.search(r"\brust\b", title):
        s += 10  # Rust central in the role title
    if re.search(r"\b(intern|internship|co-op|coop|student|apprentice)\b", title):
        s += 4
    loc = _words(job.get("location"))
    if loc:
        if US_HINTS.search(loc):
            s += 6
        elif NON_US_HINTS.search(loc):
            s -= 14
    if job.get("salary"):
        s += 3
    if job.get("contact"):
        s += 2  # a candidate contact/email exists => actionable
    return max(0, min(100, s))


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
    """Keep only known keys + sane defaults + fit score."""
    clean = {k: v for k, v in job.items() if k in VALID_KEYS and v is not None}
    clean["status"] = clean.get("status", "backlog")
    if clean["status"] not in STATUSES:
        clean["status"] = "backlog"
    for f in ("company", "title", "location"):
        clean.setdefault(f, "")
    clean.setdefault("url", "")
    clean.setdefault("deadline", "")
    clean.setdefault("notes", "")
    clean.setdefault("source", "")
    clean.setdefault("salary", "")
    clean.setdefault("contact", "")
    clean["match"] = score_job(clean)
    if job_id is None:
        seed = {k: clean[k] for k in ("company", "title", "url", "location")}
        job_id = str(hash(json.dumps(seed, sort_keys=True)) & 0xFFFFFFFF)
    clean["id"] = job_id
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
            jobs = load_data()["jobs"]
            sort = parse_qs(parsed.query).get("sort", ["added"])[0]
            if sort == "match":
                jobs = sorted(jobs, key=lambda j: (j.get("match", 0),
                                                   j.get("added_at", "")),
                              reverse=True)
            self._send(200, jobs)
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
