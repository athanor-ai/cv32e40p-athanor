#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
YOSYS = Path(os.environ.get("YOSYS", "yosys"))
CASES = {
    "positive": {"path": ROOT / "predicate_equiv/positive", "expect": "success"},
    "negative_addsub_prefix_0101": {"path": ROOT / "predicate_equiv/negative_addsub_prefix_0101", "expect": "fail"},
    "negative_div_prefix_01101": {"path": ROOT / "predicate_equiv/negative_div_prefix_01101", "expect": "fail"},
    "negative_adder_even_subs": {"path": ROOT / "predicate_equiv/negative_adder_even_subs", "expect": "fail"},
}


def run_case(path: Path) -> dict:
    proc = subprocess.run([str(YOSYS), "-s", "prove.ys"], cwd=path, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    text = proc.stdout + proc.stderr
    return {"rc": proc.returncode, "success": "no model found: SUCCESS" in text, "fail": "model found: FAIL" in text}


def main() -> int:
    expected = json.loads((ROOT / "predicate_equiv/summary.json").read_text())
    rows = {}
    failures = []
    for name, meta in CASES.items():
        got = run_case(meta["path"])
        rows[name] = {"success": got["success"], "fail": got["fail"]}
        if meta["expect"] == "success" and not (got["rc"] == 0 and got["success"] and not got["fail"]):
            failures.append(f"{name} did not prove diff_o == 0")
        if meta["expect"] == "fail" and not (got["rc"] == 0 and got["fail"] and not got["success"]):
            failures.append(f"{name} did not bite")
    receipt = {"candidate": "alu_addsub_divvalid_adderneg_prefixes", "rows": rows, "expected_log_sha_fields": {k: v["log_sha"] for k, v in expected["rows"].items()}}
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
