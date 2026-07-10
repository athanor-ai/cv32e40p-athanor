#!/usr/bin/env python3
from __future__ import annotations

import difflib
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOLD = ROOT / "gold_source.sv"
GATE = ROOT / "gate_source.sv"

OLD = 'assign shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||\n                      (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||\n                      (operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||\n                      (operator_i == ALU_REM) || (operator_i == ALU_REMU) ||\n                      (operator_i == ALU_BREV);'
NEW = "assign shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||\n                      (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||\n                      (operator_i[6:2] == 5'b01100) ||\n                      (operator_i == ALU_BREV);"


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
        failures.append(f"gold source contains old predicate {gold.count(OLD)} times")
    if gate.count(NEW) != 1:
        failures.append(f"gate source contains new predicate {gate.count(NEW)} times")
    if OLD in gate:
        failures.append("gate source still contains old predicate")
    if gold.replace(OLD, NEW) != gate:
        failures.append("gate source is not exactly gold source with one predicate replacement")

    diff = difflib.unified_diff(gold.splitlines(), gate.splitlines(), fromfile="gold_source.sv", tofile="gate_source.sv", lineterm="")
    normalized_diff = "\n".join(line.rstrip(" \t") for line in diff) + "\n"
    packaged_diff = (ROOT / "SOURCE_DIFF.patch").read_text()
    if normalized_diff != packaged_diff:
        failures.append("packaged SOURCE_DIFF.patch differs from normalized regenerated diff")
    receipt = {
        "candidate": "alu_shift_left_divrem_prefix",
        "module": "cv32e40p_alu",
        "source_delta_class": "exact_single_predicate_replacement",
        "old_predicate": OLD,
        "new_predicate": NEW,
        "gold_sha256": sha(GOLD),
        "gate_sha256": sha(GATE),
        "source_diff_sha256": hashlib.sha256(normalized_diff.encode()).hexdigest(),
        "behavioral_movements_outside_predicate": 0 if not failures else "unknown",
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
