#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = ROOT / "selected_flow/baseline/summary.json"
GATE = ROOT / "selected_flow/gate/summary.json"
IF_BASE = ROOT / "if_stage/baseline/summary.json"
IF_GATE = ROOT / "if_stage/gate/summary.json"


def compare(base: dict, gate: dict) -> tuple[float, dict[str, dict[str, float | str]], list[str]]:
    failures: list[str] = []
    area_delta_pct = (gate["area"] - base["area"]) / base["area"] * 100.0
    timing = {}
    for group, b in base["wns"].items():
        g = gate["wns"][group]
        delta = g - b
        status = "improved" if delta > 0 else "flat" if delta == 0 else "regressed"
        timing[group] = {
            "baseline": b,
            "delta": round(delta, 6),
            "gate": g,
            "status": status,
        }
        if delta < 0:
            failures.append(f"timing group {group} regressed: {b} -> {g}")
    return area_delta_pct, timing, failures


def main() -> int:
    base = json.loads(BASE.read_text())
    gate = json.loads(GATE.read_text())
    if_base = json.loads(IF_BASE.read_text())
    if_gate = json.loads(IF_GATE.read_text())
    failures: list[str] = []
    if base["top"] != "cv32e40p_prefetch_buffer" or gate["top"] != base["top"]:
        failures.append("unexpected prefetch selected-flow top")
    if if_base["top"] != "cv32e40p_if_stage" or if_gate["top"] != if_base["top"]:
        failures.append("unexpected IF-stage selected-flow top")

    area_delta_pct, timing, timing_failures = compare(base, gate)
    failures.extend(timing_failures)
    if area_delta_pct > 0:
        failures.append(f"prefetch-buffer area regressed: {area_delta_pct:.6f}%")

    if_area_delta_pct, if_timing, _ = compare(if_base, if_gate)
    if_neutral = if_gate["area"] == if_base["area"] and all(
        if_gate["wns"][group] == value for group, value in if_base["wns"].items()
    )
    receipt = {
        "candidate": "prefetch_hwlp_flush_demorgan",
        "if_stage_context": {
            "area": {
                "baseline": if_base["area"],
                "delta_pct": round(if_area_delta_pct, 6),
                "gate": if_gate["area"],
            },
            "interpretation": "neutral; not claimed as an IF-stage win",
            "neutral": if_neutral,
            "timing_slack": if_timing,
            "top": if_base["top"],
        },
        "prefetch_buffer_context": {
            "area": {
                "baseline": base["area"],
                "delta_pct": round(area_delta_pct, 6),
                "gate": gate["area"],
            },
            "timing_flat_or_improved": not any(v["status"] == "regressed" for v in timing.values()),
            "timing_slack": timing,
            "top": base["top"],
        },
        "scope": "prefetch-buffer parent context only",
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
