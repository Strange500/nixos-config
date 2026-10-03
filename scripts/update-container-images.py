#!/usr/bin/env python3
"""Refresh pinned container image digests + sha256 hashes in modules/server/images.nix.

Each image is pinned with `dockerTools.pullImage` inside a `pin.mkPinnedImage { ... }`
block carrying both the registry `imageDigest` and the flat `sha256` of the resulting
skopeo docker-archive. When an upstream tag moves, BOTH must change, so this script
re-resolves the tag's current digest and, when it differs, recomputes the hash.

Run by .github/workflows/update-images.yml; requires `skopeo` and `nix` on PATH.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

IMAGES_NIX = Path(__file__).resolve().parent.parent / "modules/server/images.nix"

# A `pin.mkPinnedImage { ... };` block. Bodies never contain a nested `};`.
BLOCK_RE = re.compile(r"pin\.mkPinnedImage\s*\{(?P<body>.*?)\};", re.DOTALL)


def field(body: str, key: str, default: str | None = None) -> str | None:
    m = re.search(rf'{key}\s*=\s*"([^"]*)"', body)
    return m.group(1) if m else default


def run(*args: str) -> str:
    return subprocess.run(
        args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    ).stdout.strip()


def registry_digest(image: str, tag: str) -> str:
    return run("skopeo", "inspect", f"docker://{image}:{tag}", "--format", "{{.Digest}}")


def archive_sha256(image: str, digest: str, tag: str) -> str:
    tar = "/tmp/pin-image.tar"
    subprocess.run(
        [
            "skopeo", "--insecure-policy", "--tmpdir=/tmp",
            "--override-os", "linux", "--override-arch", "amd64",
            "copy", "--src-tls-verify=true",
            f"docker://{image}@{digest}",
            f"docker-archive://{tar}:{image}:{tag}",
        ],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True,
    )
    return run("nix", "hash", "file", "--type", "sha256", "--sri", tar)


def main() -> int:
    text = IMAGES_NIX.read_text()
    updated: list[str] = []
    errors: list[str] = []

    def refresh(m: re.Match[str]) -> str:
        body = m.group("body")
        image = field(body, "imageName")
        tag = field(body, "finalImageTag", "latest") or "latest"
        old_digest = field(body, "imageDigest")
        old_hash = field(body, "sha256")
        if image is None or old_digest is None or old_hash is None:
            errors.append(f"unparseable block: {body.strip()[:60]!r}")
            return m.group(0)
        label = f"{image}:{tag}"
        try:
            new_digest = registry_digest(image, tag)
        except subprocess.CalledProcessError as exc:
            errors.append(f"{label}: registry lookup failed ({exc})")
            return m.group(0)
        if new_digest == old_digest:
            print(f"  = {label}")
            return m.group(0)
        try:
            new_hash = archive_sha256(image, new_digest, tag)
        except subprocess.CalledProcessError as exc:
            errors.append(f"{label}: hash recompute failed ({exc})")
            return m.group(0)
        print(f"  ^ {label}: {old_digest} -> {new_digest}")
        new_body = body.replace(
            f'imageDigest = "{old_digest}"', f'imageDigest = "{new_digest}"'
        ).replace(f'sha256 = "{old_hash}"', f'sha256 = "{new_hash}"')
        updated.append(label)
        return m.group(0).replace(body, new_body)

    new_text = BLOCK_RE.sub(refresh, text)
    if updated:
        IMAGES_NIX.write_text(new_text)

    print(f"\n{len(updated)} image(s) updated" + (f", {len(errors)} error(s)" if errors else ""))
    for e in errors:
        print(f"  ! {e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
