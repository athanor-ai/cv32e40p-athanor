#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
YOSYS = Path(os.environ.get("YOSYS", "yosys"))
CASES = {
    "positive": ROOT / "predicate_equiv/positive_prefix_01100",
    "negative": ROOT / "predicate_equiv/negative_prefix_01101",
}


def run_case(path: Path) -> dict:
    proc = subprocess.run([str(YOSYS), "-s", "prove.ys"], cwd=path, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    text = proc.stdout + proc.stderr
    return {"rc": proc.returncode, "success": "no model found: SUCCESS" in text, "fail": "model found: FAIL" in text, "text": text}


def main() -> int:
    expected = json.loads((ROOT / "predicate_equiv/summary.json").read_text())
    pos = run_case(CASES["positive"])
    neg = run_case(CASES["negative"])
    failures = []
    if not (pos["rc"] == 0 and pos["success"] and not pos["fail"]):
        failures.append("positive prefix 01100 did not prove diff_o == 0")
    if not (neg["rc"] == 0 and neg["fail"] and not neg["success"]):
        failures.append("negative prefix 01101 did not bite")
    for token in (
        r"\operator_i                   50",
        r"\old_shift_left                1",
        r"\new_shift_left                0",
        r"\diff_o                        1",
    ):
        if token not in neg["text"]:
            failures.append(f"negative log missing expected counterexample token: {token}")
    receipt = {
        "candidate": "alu_shift_left_divrem_prefix",
        "positive_prefix_01100": {"success": pos["success"], "fail": pos["fail"]},
        "negative_prefix_01101": {"success": neg["success"], "fail": neg["fail"], "counterexample_operator_i": "0110010"},
        "expected_summary_sha_fields": {
            "positive_log_sha": expected["positive"]["log_sha"],
            "negative_log_sha": expected["negative"]["log_sha"],
        },
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
