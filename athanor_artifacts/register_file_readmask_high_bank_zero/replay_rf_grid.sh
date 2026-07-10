#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YOSYS="${YOSYS:-/workdir/_tools/oss-cad-suite-20260630/bin/yosys}"
OUT_DIR="${OUT_DIR:-$ROOT/replay_out/rf_grid_equiv}"
mkdir -p "$OUT_DIR"

run_one() {
  local name="$1"
  local gate_source="$2"
  local fpu="$3"
  local zfinx="$4"
  local dir="$OUT_DIR/$name"
  mkdir -p "$dir"
  "$YOSYS" -p "read_verilog -sv $ROOT/equiv_rf_grid/gold_register_file_ff.sv; chparam -set ADDR_WIDTH 6 -set FPU $fpu -set ZFINX $zfinx cv32e40p_register_file; hierarchy -check -top cv32e40p_register_file; proc; memory; async2sync; flatten; opt; rename cv32e40p_register_file gold; write_rtlil $dir/gold.il" > "$dir/flatten_gold.log" 2>&1
  "$YOSYS" -p "read_verilog -sv $gate_source; chparam -set ADDR_WIDTH 6 -set FPU $fpu -set ZFINX $zfinx cv32e40p_register_file; hierarchy -check -top cv32e40p_register_file; proc; memory; async2sync; flatten; opt; rename cv32e40p_register_file gate; write_rtlil $dir/gate.il" > "$dir/flatten_gate.log" 2>&1
  set +e
  "$YOSYS" -p "read_rtlil $dir/gold.il; read_rtlil $dir/gate.il; opt; equiv_make gold gate equiv; hierarchy -top equiv; opt; equiv_simple; equiv_induct; equiv_status -assert" > "$dir/equiv.log" 2>&1
  local rc=$?
  set -e
  echo "$rc" > "$dir/rc"
}

run_one real_fpu0_zfinx0 "$ROOT/equiv_rf_grid/gate_register_file_ff.sv" 0 0
run_one real_fpu1_zfinx0 "$ROOT/equiv_rf_grid/gate_register_file_ff.sv" 1 0
run_one real_fpu1_zfinx1 "$ROOT/equiv_rf_grid/gate_register_file_ff.sv" 1 1
run_one neg_fpu0_zfinx0 "$ROOT/equiv_rf_grid/negative_register_file_ff.sv" 0 0

grep -q "Of those cells 1150 are proven and 0 are unproven" "$OUT_DIR/real_fpu0_zfinx0/equiv.log"
grep -q "Of those cells 2238 are proven and 0 are unproven" "$OUT_DIR/real_fpu1_zfinx0/equiv.log"
grep -q "Of those cells 1150 are proven and 0 are unproven" "$OUT_DIR/real_fpu1_zfinx1/equiv.log"
grep -q "Found a total of 32 unproven" "$OUT_DIR/neg_fpu0_zfinx0/equiv.log"
if [[ "$(cat "$OUT_DIR/neg_fpu0_zfinx0/rc")" -eq 0 ]]; then
  echo "negative control unexpectedly passed" >&2
  exit 1
fi
for d in real_fpu0_zfinx0 real_fpu1_zfinx0 real_fpu1_zfinx1; do
  if [[ "$(cat "$OUT_DIR/$d/rc")" -ne 0 ]]; then
    echo "$d failed" >&2
    exit 1
  fi
done
sha256sum "$OUT_DIR"/*/*.il "$OUT_DIR"/*/*.log > "$OUT_DIR/SHA256SUMS"
echo "register-file grid equivalence replay passed; logs in $OUT_DIR"
