#!/usr/bin/env python3
"""Opt-in OpenCode chat client. Never configures or starts a remote service."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener

CONFIG = Path(__file__).resolve().parents[1] / "examples/opencode/hermes.json"


def prepare_environment(source):
    env = dict(source)
    base = env.get("HERMES_API_BASE_URL", "")
    key = env.get("HERMES_API_KEY", "")
    if not base or not key.strip():
        raise ValueError("HERMES_API_BASE_URL and HERMES_API_KEY are required")
    if any(ord(c) < 32 or ord(c) == 127 for c in base + key):
        raise ValueError("Control characters are not allowed in URL or key")
    try:
        url = urlsplit(base)
        _ = url.port  # Validate the port before any network request.
        valid = (
            bool(url.hostname) and "@" not in url.netloc
            and not any(c.isspace() for c in base)
            and not url.query and not url.fragment and url.path.endswith("/v1")
            and (url.scheme == "https" or (
                url.scheme == "http" and url.hostname in {"localhost", "127.0.0.1", "::1"}
            ))
        )
    except ValueError:
        valid = False
    if not valid:
        raise ValueError("Use HTTPS or loopback HTTP, ending in /v1, without credentials/query/fragment")
    model = env.setdefault("HERMES_MODEL_ID", "hermes-agent")
    if not model.strip() or any(ord(c) < 32 for c in model):
        raise ValueError("HERMES_MODEL_ID must be a nonempty model ID")
    # Inline config has higher priority than normal project/global configs.
    # Keep env references: never serialize the bearer into a config file or argv.
    env["OPENCODE_CONFIG_CONTENT"] = CONFIG.read_text(encoding="utf-8")
    return env


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # Never send a bearer to a redirected destination.


def check_models(env):
    request = Request(env["HERMES_API_BASE_URL"] + "/models", headers={
        "Authorization": "Bearer " + env["HERMES_API_KEY"],
        "Accept": "application/json",
    })
    try:
        # Direct connection: no ambient proxy can intercept a loopback bearer.
        with build_opener(ProxyHandler({}), NoRedirect()).open(request, timeout=10) as response:
            raw = response.read(1024 * 1024 + 1)
        if len(raw) > 1024 * 1024:
            raise ValueError("Model response too large")
        payload = json.loads(raw)
        rows = payload.get("data") if isinstance(payload, dict) else None
        if not isinstance(rows, list):
            raise ValueError("Expected an OpenAI model list")
        if not any(isinstance(row, dict) and row.get("id") == env["HERMES_MODEL_ID"] for row in rows):
            raise ValueError("Configured HERMES_MODEL_ID is not advertised by /v1/models")
    except HTTPError as exc:
        code = exc.code
        exc.close()
        raise ValueError(f"Model preflight refused (HTTP {code}); check auth, route and redirects") from None
    except (URLError, TimeoutError, OSError):
        raise ValueError("Model preflight unreachable; check tunnel, TLS and API URL") from None
    except (UnicodeError, json.JSONDecodeError):
        raise ValueError("Model preflight did not return valid JSON") from None


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="GET models only; no inference or CLI launch")
    parser.add_argument("--workspace", type=Path, default=Path.cwd())
    parser.add_argument("args", nargs=argparse.REMAINDER, help="OpenCode arguments after --")
    options = parser.parse_args(argv)
    try:
        env = prepare_environment(os.environ)
        if not options.workspace.is_dir():
            raise ValueError("Workspace must be an existing local directory")
        check_models(env)
        if options.check:
            print("OK: authenticated model discovery; inference and local execution NOT tested")
            return 0
        binary = shutil.which(env.get("OPENCODE_BIN", "opencode"))
        if not binary:
            raise ValueError("OpenCode not found; install the documented pinned version or set OPENCODE_BIN")
        args = options.args[1:] if options.args[:1] == ["--"] else options.args
        print("Remote Hermes chat: any Hermes tools execute on the SERVER, not this workspace.", file=sys.stderr)
        return subprocess.run([binary, "--pure", *args], cwd=options.workspace, env=env, check=False).returncode
    except (ValueError, OSError) as exc:
        # OSError text can contain user-supplied paths; do not dump environment or HTTP bodies.
        message = str(exc) if isinstance(exc, ValueError) else "Local OpenCode launch failed"
        print(f"Error: {message}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
