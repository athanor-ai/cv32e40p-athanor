#!/usr/bin/env python3
"""Verify public CV32E40P receipt manifests and wording boundaries."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ARTIFACT_ROOT = ROOT / "athanor_artifacts"
PUBLIC_TEXT_PATHS = [
    ROOT / "README.md",
    ROOT / "athanor" / "README.md",
    ARTIFACT_ROOT / "README.md",
]
PRIVATE_WORDING = (
        "slack",
    "linear",
    "supabase",
    "anthropic",
    "claude",
    "asabi",
    "cody",
    "ronald",
    "quan",
    "platypus",
)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"{path.relative_to(ROOT)}: invalid JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"{path.relative_to(ROOT)}: expected JSON object")
    return data


def _check_sha_manifest(path: Path) -> None:
    base = path.parent
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            expected, rel = line.split(None, 1)
        except ValueError as exc:
            raise SystemExit(
                f"{path.relative_to(ROOT)}:{lineno}: expected '<sha256> <path>'"
            ) from exc
        rel = rel.strip()
        if rel.startswith("/"):
            raise SystemExit(
                f"{path.relative_to(ROOT)}:{lineno}: public manifest uses absolute path {rel!r}"
            )
        artifact = (base / rel).resolve()
        if not artifact.is_file():
            raise SystemExit(
                f"{path.relative_to(ROOT)}:{lineno}: missing artifact {rel!r}"
            )
        actual = _sha256(artifact)
        if actual != expected:
            raise SystemExit(
                f"{path.relative_to(ROOT)}:{lineno}: sha256 mismatch for {rel!r} "
                f"(expected {expected}, got {actual})"
            )


def _check_manifest(path: Path) -> None:
    data = _load_json(path)
    rel = path.relative_to(ROOT)
    if data.get("customer_claim_ready") is not False:
        raise SystemExit(f"{rel}: customer_claim_ready must be false")
    taxonomy = data.get("claim_taxonomy")
    if not isinstance(taxonomy, dict):
        raise SystemExit(f"{rel}: missing claim_taxonomy")
    if taxonomy.get("promotion_state") != "not_customer_ready":
        raise SystemExit(f"{rel}: promotion_state must be not_customer_ready")
    for key in ("accepted_optimization", "whole_core", "customer_impact"):
        if taxonomy.get(key) != "not_claimed":
            raise SystemExit(f"{rel}: claim_taxonomy.{key} must be not_claimed")
    boundary = str(data.get("boundary", "")).lower()
    if "no accepted" not in boundary:
        raise SystemExit(f"{rel}: boundary must explicitly deny accepted scope")
    if "no customer" not in boundary and "not a customer" not in boundary:
        raise SystemExit(f"{rel}: boundary must explicitly deny customer scope")


def _check_public_wording() -> None:
    for path in PUBLIC_TEXT_PATHS:
        text = path.read_text(encoding="utf-8")
        lowered = text.lower()
        for word in PRIVATE_WORDING:
            if word in lowered:
                raise SystemExit(
                    f"{path.relative_to(ROOT)}: public wording contains private term {word!r}"
                )


def main() -> int:
    subprocess.run(
        [sys.executable, str(ROOT / "tools" / "check_packet_toolchain_lock.py")],
        cwd=ROOT,
        check=True,
    )

    sha_manifests = sorted(ARTIFACT_ROOT.glob("*/SHA256SUMS"))
    if not sha_manifests:
        raise SystemExit("no public packet SHA256SUMS manifests found")
    for path in sha_manifests:
        _check_sha_manifest(path)

    manifests = sorted(ARTIFACT_ROOT.glob("*/*manifest*.json"))
    if not manifests:
        raise SystemExit("no public packet JSON manifests found")
    for path in manifests:
        _check_manifest(path)

    _check_public_wording()

    print(
        "verified "
        f"{len(sha_manifests)} public SHA manifests and "
        f"{len(manifests)} packet manifests"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
