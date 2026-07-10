#!/usr/bin/env python3
"""Validate CV32 packet manifests against the repository toolchain lock."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCK_PATH = ROOT / "tools" / "TOOLCHAIN.lock"
MANIFEST_ROOT = ROOT / "athanor_artifacts"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def main() -> int:
    errors: list[str] = []
    lock = json.loads(LOCK_PATH.read_text())
    lock_hash = sha256(LOCK_PATH)
    installable_tag = lock["oss_cad_suite"]["installable_release_tag"]
    yosys_prefix = lock["tools"]["yosys"]["version_prefix"]
    liberty = lock["selected_flow"]["liberty"]
    liberty_sha256 = lock["selected_flow"]["liberty_sha256"]

    manifests = sorted(MANIFEST_ROOT.rglob("*manifest*.json"))
    if not manifests:
        fail(errors, "no packet manifests found")

    for manifest in manifests:
        rel = manifest.relative_to(ROOT)
        data = json.loads(manifest.read_text())

        selected_toolchain = data.get("selected_toolchain")
        if not isinstance(selected_toolchain, dict):
            fail(errors, f"{rel}: selected_toolchain must be an object")
        else:
            yosys_version = selected_toolchain.get("yosys_version")
            if not isinstance(yosys_version, str) or not yosys_version.startswith(yosys_prefix):
                fail(errors, f"{rel}: yosys_version must start with {yosys_prefix!r}")
            if selected_toolchain.get("liberty") != liberty:
                fail(errors, f"{rel}: liberty must be {liberty!r}")
            if selected_toolchain.get("liberty_sha256") != liberty_sha256:
                fail(errors, f"{rel}: liberty_sha256 must match tools/TOOLCHAIN.lock")

        toolchain_lock = data.get("toolchain_lock")
        if not isinstance(toolchain_lock, dict):
            fail(errors, f"{rel}: toolchain_lock must be an object")
        else:
            if toolchain_lock.get("path") != "tools/TOOLCHAIN.lock":
                fail(errors, f"{rel}: toolchain_lock.path must be tools/TOOLCHAIN.lock")
            if toolchain_lock.get("sha256") != lock_hash:
                fail(errors, f"{rel}: toolchain_lock.sha256 does not match current lock")
            if toolchain_lock.get("installable_release_tag") != installable_tag:
                fail(errors, f"{rel}: toolchain_lock.installable_release_tag must be {installable_tag!r}")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print(f"validated {len(manifests)} packet manifests against {LOCK_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
