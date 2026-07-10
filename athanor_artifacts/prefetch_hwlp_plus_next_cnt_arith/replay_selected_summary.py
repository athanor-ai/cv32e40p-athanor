#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def compare(base: dict, gate: dict) -> tuple[float, dict[str, dict[str, float | str]]]:
    area_delta_pct = (gate["area"] - base["area"]) / base["area"] * 100.0
    timing = {}
    for group, b in base["wns"].items():
        g = gate["wns"][group]
        delta = g - b
        timing[group] = {
            "baseline": b,
            "gate": g,
            "delta": round(delta, 6),
            "status": "improved" if delta > 0 else "flat" if delta == 0 else "regressed",
        }
    return area_delta_pct, timing


def main() -> int:
    if_base = json.loads((ROOT / "if_stage/baseline/summary.json").read_text())
    if_gate = json.loads((ROOT / "if_stage/gate/summary.json").read_text())
    pref_base = json.loads((ROOT / "prefetch_buffer/baseline/summary.json").read_text())
    pref_gate = json.loads((ROOT / "prefetch_buffer/gate/summary.json").read_text())
    failures = []
    if if_base["top"] != "cv32e40p_if_stage" or if_gate["top"] != if_base["top"]:
        failures.append("unexpected IF-stage top")
    if pref_base["top"] != "cv32e40p_prefetch_buffer" or pref_gate["top"] != pref_base["top"]:
        failures.append("unexpected prefetch-buffer top")
    if_area_delta_pct, if_timing = compare(if_base, if_gate)
    pref_area_delta_pct, pref_timing = compare(pref_base, pref_gate)
    if if_area_delta_pct > 0:
        failures.append(f"IF-stage area regressed: {if_area_delta_pct:.6f}%")
    if_regressed = [k for k, v in if_timing.items() if v["status"] == "regressed"]
    if if_regressed:
        failures.append(f"IF-stage timing regressed: {if_regressed}")
    if pref_area_delta_pct > 0:
        failures.append(f"prefetch-buffer local area regressed: {pref_area_delta_pct:.6f}%")
    pref_regressed = [k for k, v in pref_timing.items() if v["status"] == "regressed"]
    if pref_regressed != ["in2out"]:
        failures.append(f"expected exactly named local prefetch-buffer in2out regression, got {pref_regressed}")
    receipt = {
        "candidate": "prefetch_hwlp_plus_next_cnt_arith",
        "classification": "if_stage_scoped_win_with_named_prefetch_buffer_in2out_regression",
        "claim_scope": {
            "top": if_base["top"],
            "area": {"baseline": if_base["area"], "gate": if_gate["area"], "delta_pct": round(if_area_delta_pct, 6)},
            "timing_slack": if_timing,
            "timing_flat_or_improved": not if_regressed,
        },
        "local_caveat_scope": {
            "top": pref_base["top"],
            "area": {"baseline": pref_base["area"], "gate": pref_gate["area"], "delta_pct": round(pref_area_delta_pct, 6)},
            "timing_slack": pref_timing,
            "named_regression_groups": pref_regressed,
            "interpretation": "local prefetch-buffer in2out regression is a first-class caveat; IF-stage is the claim scope",
        },
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
