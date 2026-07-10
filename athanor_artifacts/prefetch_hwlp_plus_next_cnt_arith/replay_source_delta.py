#!/usr/bin/env python3
from __future__ import annotations

import difflib
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOLD = ROOT / "gold_source.sv"
GATE = ROOT / "gate_source.sv"
REPLACEMENTS = [("always_comb begin\n    case ({\n      count_up, count_down\n    })\n      2'b00: begin\n        next_cnt = cnt_q;\n      end\n      2'b01: begin\n        next_cnt = cnt_q - 1'b1;\n      end\n      2'b10: begin\n        next_cnt = cnt_q + 1'b1;\n      end\n      2'b11: begin\n        next_cnt = cnt_q;\n      end\n    endcase\n  end", 'assign next_cnt = cnt_q + count_up - count_down;'), ('assign hwlp_flush_resp        = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);', 'assign hwlp_flush_resp        = hwlp_jump_i && (!fifo_empty_i || resp_valid_i);')]


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
            failures.append(f"gold source contains expected old replacement {gold.count(old)} times: {old[:80]!r}")
        if gate.count(new) != 1:
            failures.append(f"gate source contains expected new replacement {gate.count(new)} times: {new[:80]!r}")
        if old in gate:
            failures.append(f"gate source still contains old replacement: {old[:80]!r}")
        transformed = transformed.replace(old, new)
    if transformed != gate:
        failures.append("gate source is not exactly gold source with the two replacements")
    diff = difflib.unified_diff(gold.splitlines(), gate.splitlines(), fromfile="gold_source.sv", tofile="gate_source.sv", lineterm="")
    normalized_diff = "\n".join(line.rstrip(" \t") for line in diff) + "\n"
    if normalized_diff != (ROOT / "SOURCE_DIFF.patch").read_text():
        failures.append("packaged SOURCE_DIFF.patch differs from normalized regenerated diff")
    receipt = {
        "candidate": "prefetch_hwlp_plus_next_cnt_arith",
        "module": "cv32e40p_prefetch_controller",
        "source_delta_class": "exact_two_replacements",
        "replacement_count": len(REPLACEMENTS),
        "gold_sha256": sha(GOLD),
        "gate_sha256": sha(GATE),
        "source_diff_sha256": hashlib.sha256(normalized_diff.encode()).hexdigest(),
        "behavioral_movements_outside_replacements": 0 if not failures else "unknown",
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
