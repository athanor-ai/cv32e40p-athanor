#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

EXPECTED = {
    "area": {"baseline": 29548.3392, "gate": 29513.3056},
    "timing": {
        "overall": {"baseline": -20.2186, "gate": -14.418},
        "reg2reg": {"baseline": -4.9985, "gate": -3.9626},
        "reg2out": {"baseline": -2.4968, "gate": -1.8351},
        "in2reg": {"baseline": -16.2551, "gate": -11.4272},
        "in2out": {"baseline": -20.2186, "gate": -14.418},
    },
}


def load(which: str) -> dict:
    return json.loads((ROOT / "selected_flow" / which / "summary.json").read_text())


def close(a: float, b: float) -> bool:
    return abs(a - b) <= 1e-6


def main() -> int:
    baseline = load("baseline")
    gate = load("gate")
    failures: list[str] = []
    measured = {
        "area": {"baseline": baseline["area"], "gate": gate["area"]},
        "timing": {group: {"baseline": baseline["wns"][group], "gate": gate["wns"][group]} for group in EXPECTED["timing"]},
    }
    for side in ("baseline", "gate"):
        if not close(measured["area"][side], EXPECTED["area"][side]):
            failures.append(f"area {side}: {measured['area'][side]} != {EXPECTED['area'][side]}")
    for group in EXPECTED["timing"]:
        for side in ("baseline", "gate"):
            if not close(measured["timing"][group][side], EXPECTED["timing"][group][side]):
                failures.append(
                    f"timing {group} {side}: {measured['timing'][group][side]} != {EXPECTED['timing'][group][side]}"
                )
    area_delta_pct = (measured["area"]["gate"] - measured["area"]["baseline"]) / measured["area"]["baseline"] * 100.0
    status = {
        "top": "cv32e40p_alu_parent_context",
        "scope": "default ALU parent context",
        "area_delta_pct": round(area_delta_pct, 6),
        "area_improved": measured["area"]["gate"] < measured["area"]["baseline"],
        "timing_flat_or_improved": all(
            measured["timing"][group]["gate"] >= measured["timing"][group]["baseline"]
            for group in measured["timing"]
        ),
        "measured": measured,
    }
    print(json.dumps(status, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    if not status["area_improved"] or not status["timing_flat_or_improved"]:
        raise SystemExit("selected-flow joint bar failed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
