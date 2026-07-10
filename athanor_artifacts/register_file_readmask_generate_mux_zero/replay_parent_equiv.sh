#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YOSYS="${YOSYS:-/workdir/_tools/oss-cad-suite-20260630/bin/yosys}"
OUT_DIR="${OUT_DIR:-$ROOT/replay_out/parent_equiv}"
mkdir -p "$OUT_DIR"
"$YOSYS" -p "read_verilog $ROOT/gold_idstage_default.v; hierarchy -check -top cv32e40p_id_stage; proc; memory; async2sync; flatten; opt; rename cv32e40p_id_stage gold; write_rtlil $OUT_DIR/gold.il" > "$OUT_DIR/flatten_gold.log" 2>&1
"$YOSYS" -p "read_verilog $ROOT/gate_idstage_default.v; hierarchy -check -top cv32e40p_id_stage; proc; memory; async2sync; flatten; opt; rename cv32e40p_id_stage gate; write_rtlil $OUT_DIR/gate.il" > "$OUT_DIR/flatten_gate.log" 2>&1
"$YOSYS" -p "read_rtlil $OUT_DIR/gold.il; read_rtlil $OUT_DIR/gate.il; opt; equiv_make gold gate equiv; hierarchy -top equiv; opt; equiv_simple; equiv_induct; equiv_status -assert" > "$OUT_DIR/yosys_equiv.log" 2>&1
grep -q "Equivalence successfully proven" "$OUT_DIR/yosys_equiv.log"
grep -q "Of those cells 2820 are proven and 0 are unproven" "$OUT_DIR/yosys_equiv.log"
"$YOSYS" -p "read_verilog $ROOT/equiv_idstage/negative_idstage_default.v; hierarchy -check -top cv32e40p_id_stage; proc; memory; async2sync; flatten; opt; rename cv32e40p_id_stage gate; write_rtlil $OUT_DIR/negative_gate.il" > "$OUT_DIR/flatten_negative_gate.log" 2>&1
set +e
"$YOSYS" -p "read_rtlil $OUT_DIR/gold.il; read_rtlil $OUT_DIR/negative_gate.il; opt; equiv_make gold gate equiv; hierarchy -top equiv; opt; equiv_simple; equiv_induct; equiv_status -assert" > "$OUT_DIR/negative_yosys_equiv.log" 2>&1
negative_rc=$?
set -e
if [[ "$negative_rc" -eq 0 ]]; then
  echo "negative control unexpectedly passed" >&2
  exit 1
fi
grep -q "Found a total of 32 unproven" "$OUT_DIR/negative_yosys_equiv.log"
sha256sum "$OUT_DIR"/*.il "$OUT_DIR"/*.log > "$OUT_DIR/SHA256SUMS"
echo "parent equivalence replay passed; logs in $OUT_DIR"
