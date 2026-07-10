#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YOSYS="${YOSYS:-/workdir/_tools/oss-cad-suite-20260630/bin/yosys}"
OUT_DIR="${OUT_DIR:-$ROOT/replay_out/parent_equiv}"
mkdir -p "$OUT_DIR"
expect_unproven_count() {
  local log="$1"
  local expected="$2"
  local label="$3"
  python3 - "$log" "$expected" "$label" <<'PY'
import re
import sys
from pathlib import Path

log = Path(sys.argv[1])
expected = int(sys.argv[2])
label = sys.argv[3]
text = log.read_text(errors="replace")
counts = []
for match in re.finditer(
    r"(?:Found(?: a total of)?\s+(\d+)\s+unproven\b|"
    r"Of those cells\s+\d+\s+are proven and\s+(\d+)\s+are unproven\b)",
    text,
):
    counts.append(int(match.group(1) or match.group(2)))
if "Equivalence successfully proven" in text:
    counts.append(0)
if not counts:
    print(f"{label}: no unproven-count verdict in {log}", file=sys.stderr)
    sys.exit(1)
actual = counts[-1]
if actual != expected:
    print(
        f"{label}: expected final unproven count {expected}, got {actual} in {log}",
        file=sys.stderr,
    )
    sys.exit(1)
PY
}

"$YOSYS" -p "read_verilog $ROOT/gold_idstage_default.v; hierarchy -check -top cv32e40p_id_stage; proc; memory; async2sync; flatten; opt; rename cv32e40p_id_stage gold; write_rtlil $OUT_DIR/gold.il" > "$OUT_DIR/flatten_gold.log" 2>&1
"$YOSYS" -p "read_verilog $ROOT/gate_idstage_default.v; hierarchy -check -top cv32e40p_id_stage; proc; memory; async2sync; flatten; opt; rename cv32e40p_id_stage gate; write_rtlil $OUT_DIR/gate.il" > "$OUT_DIR/flatten_gate.log" 2>&1
"$YOSYS" -p "read_rtlil $OUT_DIR/gold.il; read_rtlil $OUT_DIR/gate.il; opt; equiv_make gold gate equiv; hierarchy -top equiv; opt; equiv_simple; equiv_induct; equiv_status -assert" > "$OUT_DIR/yosys_equiv.log" 2>&1
expect_unproven_count "$OUT_DIR/yosys_equiv.log" 0 "parent positive"

"$YOSYS" -p "read_verilog $ROOT/equiv_idstage/negative_idstage_default.v; hierarchy -check -top cv32e40p_id_stage; proc; memory; async2sync; flatten; opt; rename cv32e40p_id_stage gate; write_rtlil $OUT_DIR/negative_gate.il" > "$OUT_DIR/flatten_negative_gate.log" 2>&1
set +e
"$YOSYS" -p "read_rtlil $OUT_DIR/gold.il; read_rtlil $OUT_DIR/negative_gate.il; opt; equiv_make gold gate equiv; hierarchy -top equiv; opt; equiv_simple; equiv_induct; equiv_status -assert" > "$OUT_DIR/negative_yosys_equiv.log" 2>&1
negative_rc=$?
set -e
if [[ "$negative_rc" -eq 0 ]]; then
  echo "negative control unexpectedly passed" >&2
  exit 1
fi
expect_unproven_count "$OUT_DIR/negative_yosys_equiv.log" 32 "parent negative"
sha256sum "$OUT_DIR"/*.il "$OUT_DIR"/*.log > "$OUT_DIR/SHA256SUMS"
echo "parent equivalence replay passed; logs in $OUT_DIR"
