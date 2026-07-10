#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
YOSYS = Path(os.environ.get("YOSYS", "/workdir/_tools/oss-cad-suite-20260630/bin/yosys"))
CASES = {
    "positive": {"expect": "success", "path": ROOT / "predicate_equiv/positive"},
    "negative_missing_bit12": {"expect": "fail", "path": ROOT / "predicate_equiv/negative_missing_bit12"},
    "negative_missing_bit2": {"expect": "fail", "path": ROOT / "predicate_equiv/negative_missing_bit2"},
}


def run_case(path: Path) -> dict:
    proc = subprocess.run([str(YOSYS), "-s", "prove.ys"], cwd=path, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    text = proc.stdout + proc.stderr
    return {"rc": proc.returncode, "success": "no model found: SUCCESS" in text, "fail": "model found: FAIL" in text}


def main() -> int:
    expected = json.loads((ROOT / "predicate_equiv/summary.json").read_text())
    failures = []
    rows = {}
    for name, meta in CASES.items():
        got = run_case(meta["path"])
        rows[name] = {"fail": got["fail"], "success": got["success"]}
        if meta["expect"] == "success" and not (got["rc"] == 0 and got["success"] and not got["fail"]):
            failures.append(f"{name} did not prove diff_o == 0")
        if meta["expect"] == "fail" and not (got["rc"] == 0 and got["fail"] and not got["success"]):
            failures.append(f"{name} did not bite")
    receipt = {
        "candidate": "compressed_decoder_l244_addi16sp_lui_zero_reduce",
        "expected_log_sha_fields": {k: v["log_sha256"] for k, v in expected["rows"].items()},
        "rows": rows,
    }
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
