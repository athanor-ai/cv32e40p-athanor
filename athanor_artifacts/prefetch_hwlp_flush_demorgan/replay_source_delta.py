#!/usr/bin/env python3
from __future__ import annotations

import difflib
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOLD = ROOT / "gold_source.sv"
GATE = ROOT / "gate_source.sv"

OLD = "assign hwlp_flush_resp        = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);"
NEW = "assign hwlp_flush_resp        = hwlp_jump_i && (!fifo_empty_i || resp_valid_i);"


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    gold = GOLD.read_text()
    gate = GATE.read_text()
    failures: list[str] = []

    if gold.count(OLD) != 1:
        failures.append(f"gold source contains expected old predicate {gold.count(OLD)} times")
    if gate.count(NEW) != 1:
        failures.append(f"gate source contains expected new predicate {gate.count(NEW)} times")
    if OLD in gate:
        failures.append("gate source still contains old predicate")
    transformed = gold.replace(OLD, NEW)
    if transformed != gate:
        failures.append("gate source is not exactly gold source with the one predicate replacement")

    diff = difflib.unified_diff(
        gold.splitlines(),
        gate.splitlines(),
        fromfile="gold_source.sv",
        tofile="gate_source.sv",
        lineterm="",
    )
    normalized_diff = "\n".join(line.rstrip(" \t") for line in diff) + "\n"
    if normalized_diff != (ROOT / "SOURCE_DIFF.patch").read_text():
        failures.append("packaged SOURCE_DIFF.patch differs from normalized regenerated diff")

    receipt = {
        "behavioral_movements_outside_predicate": 0 if not failures else "unknown",
        "candidate": "prefetch_hwlp_flush_demorgan",
        "gate_sha256": sha(GATE),
        "gold_sha256": sha(GOLD),
        "module": "cv32e40p_prefetch_controller",
        "replacement_count": 1,
        "source_delta_class": "exact_single_predicate_replacement",
        "source_diff_sha256": hashlib.sha256(normalized_diff.encode()).hexdigest(),
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
