#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def compare(base: dict, gate: dict, top: str) -> dict:
    failures = []
    if base["top"] != top or gate["top"] != top:
        failures.append(f"unexpected top for {top}")
    area_delta_pct = (gate["area"] - base["area"]) / base["area"] * 100.0
    timing = {}
    for group, bval in base["wns"].items():
        gval = gate["wns"][group]
        if bval is None or gval is None:
            timing[group] = {"baseline": bval, "gate": gval, "delta": None, "status": "not_applicable"}
            continue
        delta = gval - bval
        timing[group] = {"baseline": bval, "gate": gval, "delta": round(delta, 6), "status": "improved" if delta > 0 else "flat" if delta == 0 else "regressed"}
        if delta < 0:
            failures.append(f"{top} timing group {group} regressed: {bval} -> {gval}")
    if area_delta_pct > 0:
        failures.append(f"{top} area regressed: {area_delta_pct:.6f}%")
    return {
        "area": {"baseline": base["area"], "gate": gate["area"], "delta_pct": round(area_delta_pct, 6)},
        "failures": failures,
        "timing_slack": timing,
        "top": top,
    }


def main() -> int:
    if_base = json.loads((ROOT / "selected_flow/baseline/summary.json").read_text())
    if_gate = json.loads((ROOT / "selected_flow/gate/summary.json").read_text())
    mod_base = json.loads((ROOT / "module_flow/baseline/summary.json").read_text())
    mod_gate = json.loads((ROOT / "module_flow/gate/summary.json").read_text())
    parent = compare(if_base, if_gate, "cv32e40p_if_stage")
    module = compare(mod_base, mod_gate, "cv32e40p_compressed_decoder")
    receipt = {
        "candidate": "compressed_decoder_l71_addi4spn_zero_reduce",
        "compressed_decoder_module": module,
        "if_stage_parent": parent,
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    failures = [*parent["failures"], *module["failures"]]
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
