#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

EXPECTED = {
    "area": {"baseline": 111291.7376, "gate": 110963.9232},
    "timing": {
        "overall": {"baseline": -10.2941, "gate": -10.2198},
        "reg2reg": {"baseline": -4.3976, "gate": -4.3976},
        "reg2out": {"baseline": -2.0943, "gate": -2.0943},
        "in2reg": {"baseline": -10.2941, "gate": -10.2198},
        "in2out": {"baseline": -4.0621, "gate": -3.7434},
    },
}


def area(which: str) -> float:
    report = ROOT / "selected_flow" / which / "reports" / "area.rpt"
    for line in report.read_text().splitlines():
        if "Chip area" in line:
            return float(line.split()[-1])
    raise SystemExit(f"missing Chip area in {report}")


def worst_slack(which: str, group: str) -> float:
    report = ROOT / "selected_flow" / which / "reports" / "timing" / f"{group}.csv.rpt"
    vals = []
    for line in report.read_text().splitlines()[1:]:
        fields = line.split(",")
        if len(fields) > 2 and fields[2]:
            vals.append(float(fields[2]))
    if not vals:
        raise SystemExit(f"missing timing values in {report}")
    return min(vals)


def close(a: float, b: float) -> bool:
    return abs(a - b) <= 1e-6


def main() -> None:
    got = {
        "area": {"baseline": area("baseline"), "gate": area("gate")},
        "timing": {
            group: {
                "baseline": worst_slack("baseline", group),
                "gate": worst_slack("gate", group),
            }
            for group in EXPECTED["timing"]
        },
    }
    failures = []
    for side in ("baseline", "gate"):
        if not close(got["area"][side], EXPECTED["area"][side]):
            failures.append(f"area {side}: {got['area'][side]} != {EXPECTED['area'][side]}")
    for group, expected in EXPECTED["timing"].items():
        for side in ("baseline", "gate"):
            if not close(got["timing"][group][side], expected[side]):
                failures.append(
                    f"timing {group} {side}: {got['timing'][group][side]} != {expected[side]}"
                )
    area_delta_pct = (got["area"]["gate"] - got["area"]["baseline"]) / got["area"]["baseline"] * 100.0
    status = {
        "top": "cv32e40p_id_stage",
        "scope": "default parent context only",
        "area_delta_pct": round(area_delta_pct, 6),
        "area_improved": got["area"]["gate"] < got["area"]["baseline"],
        "timing_flat_or_improved": all(
            got["timing"][group]["gate"] >= got["timing"][group]["baseline"]
            for group in got["timing"]
        ),
        "measured": got,
    }
    print(json.dumps(status, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    if not status["area_improved"] or not status["timing_flat_or_improved"]:
        raise SystemExit("selected-flow joint bar failed")


if __name__ == "__main__":
    main()
