#!/usr/bin/env python3
from __future__ import annotations

import difflib
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOLD = ROOT / "gold_source.sv"
GATE = ROOT / "gate_source.sv"
REPLACEMENTS = [('assign shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||\n                      (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||\n                      (operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||\n                      (operator_i == ALU_REM) || (operator_i == ALU_REMU) ||\n                      (operator_i == ALU_BREV);', "assign shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||\n                      (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||\n                      (operator_i[6:2] == 5'b01100) ||\n                      (operator_i == ALU_BREV);"), ('assign div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||\n                     (operator_i == ALU_REM) || (operator_i == ALU_REMU));', "assign div_valid = enable_i & (operator_i[6:2] == 5'b01100);"), ('assign adder_op_b_negate = (operator_i == ALU_SUB) || (operator_i == ALU_SUBR) ||\n                             (operator_i == ALU_SUBU) || (operator_i == ALU_SUBUR) || is_subrot_i;', "assign adder_op_b_negate = ((operator_i[6:3] == 4'b0011) & operator_i[0]) | is_subrot_i;")]


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
    transformed = gold
    for old, new in REPLACEMENTS:
        if gold.count(old) != 1:
            failures.append(f"gold source contains expected old predicate {gold.count(old)} times: {old[:80]!r}")
        if gate.count(new) != 1:
            failures.append(f"gate source contains expected new predicate {gate.count(new)} times: {new[:80]!r}")
        if old in gate:
            failures.append(f"gate source still contains old predicate: {old[:80]!r}")
        transformed = transformed.replace(old, new)
    if transformed != gate:
        failures.append("gate source is not exactly gold source with the three predicate replacements")
    diff = difflib.unified_diff(gold.splitlines(), gate.splitlines(), fromfile="gold_source.sv", tofile="gate_source.sv", lineterm="")
    normalized_diff = "\n".join(line.rstrip(" \t") for line in diff) + "\n"
    if normalized_diff != (ROOT / "SOURCE_DIFF.patch").read_text():
        failures.append("packaged SOURCE_DIFF.patch differs from normalized regenerated diff")
    receipt = {
        "candidate": "alu_shift_divvalid_adderneg_prefixes",
        "module": "cv32e40p_alu",
        "source_delta_class": "exact_three_predicate_replacements",
        "replacement_count": len(REPLACEMENTS),
        "gold_sha256": sha(GOLD),
        "gate_sha256": sha(GATE),
        "source_diff_sha256": hashlib.sha256(normalized_diff.encode()).hexdigest(),
        "behavioral_movements_outside_predicates": 0 if not failures else "unknown",
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
