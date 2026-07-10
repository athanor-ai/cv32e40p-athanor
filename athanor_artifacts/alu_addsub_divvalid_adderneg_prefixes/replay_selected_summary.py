#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = ROOT / "selected_flow/baseline/summary.json"
GATE = ROOT / "selected_flow/gate/summary.json"


def main() -> int:
    base = json.loads(BASE.read_text())
    gate = json.loads(GATE.read_text())
    failures = []
    if base["top"] != "cv32e40p_alu_parent_context" or gate["top"] != base["top"]:
        failures.append("unexpected selected-flow top")
    area_delta_pct = (gate["area"] - base["area"]) / base["area"] * 100.0
    timing = {}
    for group, b in base["wns"].items():
        g = gate["wns"][group]
        delta = g - b
        timing[group] = {"baseline": b, "gate": g, "delta": round(delta, 6), "status": "improved" if delta > 0 else "flat" if delta == 0 else "regressed"}
        if delta < 0:
            failures.append(f"timing group {group} regressed: {b} -> {g}")
    if area_delta_pct > 0:
        failures.append(f"area regressed: {area_delta_pct:.6f}%")
    receipt = {"candidate": "alu_addsub_divvalid_adderneg_prefixes", "scope": "default ALU parent context", "top": base["top"], "area": {"baseline": base["area"], "gate": gate["area"], "delta_pct": round(area_delta_pct, 6)}, "timing_slack": timing, "timing_flat_or_improved": not any(v["status"] == "regressed" for v in timing.values())}
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
