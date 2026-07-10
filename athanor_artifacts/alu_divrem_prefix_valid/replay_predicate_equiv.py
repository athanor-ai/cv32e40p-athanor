#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
YOSYS = Path(os.environ.get("YOSYS", "/workdir/_tools/oss-cad-suite-20260630/bin/yosys"))
OUT = Path(os.environ.get("OUT_DIR", "/tmp/cv32-alu-divrem-prefix-predicate-replay"))


def run_case(label: str, expect: str) -> dict[str, object]:
    source_dir = ROOT / "predicate_equiv" / label
    work = OUT / label
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    shutil.copy2(source_dir / "divvalid_expr_miter.sv", work / "divvalid_expr_miter.sv")
    ys = work / "prove.ys"
    ys.write_text(
        f"""
read_verilog -sv {work / 'divvalid_expr_miter.sv'}
prep -top divvalid_expr_miter
sat -prove diff_o 0 -show enable_i,operator_i,old_div_valid,new_div_valid,diff_o
"""
    )
    proc = subprocess.run([str(YOSYS), "-s", str(ys)], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    log = proc.stdout + proc.stderr
    (work / "yosys_sat.log").write_text(log)
    success = "no model found: SUCCESS" in log
    fail = "model found: FAIL" in log
    row: dict[str, object] = {
        "label": label,
        "rc": proc.returncode,
        "success": success,
        "fail": fail,
    }
    if fail:
        wanted = {"operator_i", "old_div_valid", "new_div_valid", "diff_o"}
        for line in log.splitlines():
            fields = line.split()
            if len(fields) >= 4 and fields[0].startswith("\\"):
                name = fields[0][1:]
                if name in wanted:
                    row[name] = fields[-1]
    if expect == "success" and not success:
        raise SystemExit(f"{label}: expected proof success")
    if expect == "fail" and not fail:
        raise SystemExit(f"{label}: expected biting failure")
    return row


def main() -> int:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    summary = {
        "positive": run_case("positive_prefix_01100", "success"),
        "negative": run_case("negative_prefix_01101", "fail"),
        "classification": "source_local_output_level_sat_equivalence_with_wrong_prefix_bite",
    }
    if summary["negative"].get("diff_o") != "1":
        raise SystemExit("negative control did not expose diff_o=1")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
