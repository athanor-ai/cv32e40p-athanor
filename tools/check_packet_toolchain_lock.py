#!/usr/bin/env python3
"""Validate CV32 packet manifests against repository policy."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCK_PATH = ROOT / "tools" / "TOOLCHAIN.lock"
MANIFEST_ROOT = ROOT / "athanor_artifacts"
TAXONOMY_SCHEMA = "cv32_claim_taxonomy_v1"
ALLOWED_TAXONOMY_STATUSES = {"evidence_packet", "auxiliary_evidence_manifest"}
NOT_CUSTOMER_READY = "not_customer_ready"
NOT_CLAIMED = "not_claimed"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def _get_str(mapping: dict[str, object], key: str) -> str | None:
    value = mapping.get(key)
    return value if isinstance(value, str) and value else None


def validate_claim_taxonomy(errors: list[str], rel: Path, data: dict[str, object]) -> None:
    taxonomy = data.get("claim_taxonomy")
    if not isinstance(taxonomy, dict):
        fail(errors, f"{rel}: claim_taxonomy must be an object")
        return

    if taxonomy.get("schema") != TAXONOMY_SCHEMA:
        fail(errors, f"{rel}: claim_taxonomy.schema must be {TAXONOMY_SCHEMA!r}")
    if taxonomy.get("status") not in ALLOWED_TAXONOMY_STATUSES:
        fail(errors, f"{rel}: claim_taxonomy.status must be one of {sorted(ALLOWED_TAXONOMY_STATUSES)!r}")
    if taxonomy.get("promotion_state") != NOT_CUSTOMER_READY:
        fail(errors, f"{rel}: claim_taxonomy.promotion_state must be {NOT_CUSTOMER_READY!r}")

    if data.get("customer_claim_ready") is not False:
        fail(errors, f"{rel}: customer_claim_ready must be false while promotion_state is not_customer_ready")

    for field in ("accepted_optimization", "whole_core", "customer_impact"):
        if taxonomy.get(field) != NOT_CLAIMED:
            fail(errors, f"{rel}: claim_taxonomy.{field} must be {NOT_CLAIMED!r}")

    for field in ("claim_scope", "ppa_scope", "semantic_equivalence_scope"):
        if not _get_str(taxonomy, field):
            fail(errors, f"{rel}: claim_taxonomy.{field} must be a non-empty string")

    boundary = data.get("boundary")
    if not isinstance(boundary, str):
        fail(errors, f"{rel}: boundary must be a string")
    else:
        lowered = boundary.lower()
        if "no accepted" not in lowered:
            fail(errors, f"{rel}: boundary must explicitly say there is no accepted optimization claim")
        if "no whole-core" not in lowered and "no full-core" not in lowered and "not a whole-core claim" not in lowered:
            fail(errors, f"{rel}: boundary must explicitly deny whole/full-core scope")
        if "no customer" not in lowered and "not a customer" not in lowered:
            fail(errors, f"{rel}: boundary must explicitly deny customer impact scope")

    if taxonomy.get("status") == "evidence_packet" and not _get_str(data, "classification"):
        fail(errors, f"{rel}: evidence packet manifests must carry top-level classification")

    if "dual_scope" in str(data.get("schema", "")) or "dual-scope" in str(data.get("boundary", "")).lower():
        if not _get_str(taxonomy, "local_caveat"):
            fail(errors, f"{rel}: dual-scope packets must name claim_taxonomy.local_caveat")


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

        validate_claim_taxonomy(errors, rel, data)

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print(f"validated {len(manifests)} packet manifests against {LOCK_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
