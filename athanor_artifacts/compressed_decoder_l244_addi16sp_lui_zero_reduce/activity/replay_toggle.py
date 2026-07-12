#!/usr/bin/env python3
from __future__ import annotations

import gzip
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

PACKAGE = Path(__file__).resolve().parents[1]
GOLD = PACKAGE / "gold_if_stage_parent.v"
GATE = PACKAGE / "gate_if_stage_parent.v"
OUT = Path(os.environ.get("OUT_DIR", "/tmp/cv32-compressed-l244-activity"))
IVERILOG = Path(os.environ.get("IVERILOG", "iverilog"))
VVP = Path(os.environ.get("VVP", "vvp"))

TB = r"""
`timescale 1ns/1ps
module tb;
  reg clk;
  reg rst_n;
  reg [23:0] m_trap_base_addr_i;
  reg [23:0] u_trap_base_addr_i;
  reg [1:0] trap_addr_mux_i;
  reg [31:0] boot_addr_i;
  reg [31:0] dm_exception_addr_i;
  reg [31:0] dm_halt_addr_i;
  reg req_i;
  wire instr_req_o;
  wire [31:0] instr_addr_o;
  reg instr_gnt_i;
  reg instr_rvalid_i;
  reg [31:0] instr_rdata_i;
  reg instr_err_i;
  reg instr_err_pmp_i;
  wire instr_valid_id_o;
  wire [31:0] instr_rdata_id_o;
  wire is_compressed_id_o;
  wire illegal_c_insn_id_o;
  wire [31:0] pc_if_o;
  wire [31:0] pc_id_o;
  wire is_fetch_failed_o;
  reg clear_instr_valid_i;
  reg pc_set_i;
  reg [31:0] mepc_i;
  reg [31:0] uepc_i;
  reg [31:0] depc_i;
  reg [3:0] pc_mux_i;
  reg [2:0] exc_pc_mux_i;
  reg [4:0] m_exc_vec_pc_mux_i;
  reg [4:0] u_exc_vec_pc_mux_i;
  wire csr_mtvec_init_o;
  reg [31:0] jump_target_id_i;
  reg [31:0] jump_target_ex_i;
  reg hwlp_jump_i;
  reg [31:0] hwlp_target_i;
  reg halt_if_i;
  reg id_ready_i;
  wire if_busy_o;
  wire perf_imiss_o;

  cv32e40p_if_stage dut (
    .clk(clk),
    .rst_n(rst_n),
    .m_trap_base_addr_i(m_trap_base_addr_i),
    .u_trap_base_addr_i(u_trap_base_addr_i),
    .trap_addr_mux_i(trap_addr_mux_i),
    .boot_addr_i(boot_addr_i),
    .dm_exception_addr_i(dm_exception_addr_i),
    .dm_halt_addr_i(dm_halt_addr_i),
    .req_i(req_i),
    .instr_req_o(instr_req_o),
    .instr_addr_o(instr_addr_o),
    .instr_gnt_i(instr_gnt_i),
    .instr_rvalid_i(instr_rvalid_i),
    .instr_rdata_i(instr_rdata_i),
    .instr_err_i(instr_err_i),
    .instr_err_pmp_i(instr_err_pmp_i),
    .instr_valid_id_o(instr_valid_id_o),
    .instr_rdata_id_o(instr_rdata_id_o),
    .is_compressed_id_o(is_compressed_id_o),
    .illegal_c_insn_id_o(illegal_c_insn_id_o),
    .pc_if_o(pc_if_o),
    .pc_id_o(pc_id_o),
    .is_fetch_failed_o(is_fetch_failed_o),
    .clear_instr_valid_i(clear_instr_valid_i),
    .pc_set_i(pc_set_i),
    .mepc_i(mepc_i),
    .uepc_i(uepc_i),
    .depc_i(depc_i),
    .pc_mux_i(pc_mux_i),
    .exc_pc_mux_i(exc_pc_mux_i),
    .m_exc_vec_pc_mux_i(m_exc_vec_pc_mux_i),
    .u_exc_vec_pc_mux_i(u_exc_vec_pc_mux_i),
    .csr_mtvec_init_o(csr_mtvec_init_o),
    .jump_target_id_i(jump_target_id_i),
    .jump_target_ex_i(jump_target_ex_i),
    .hwlp_jump_i(hwlp_jump_i),
    .hwlp_target_i(hwlp_target_i),
    .halt_if_i(halt_if_i),
    .id_ready_i(id_ready_i),
    .if_busy_o(if_busy_o),
    .perf_imiss_o(perf_imiss_o)
  );

  integer cycle;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  function [15:0] c1_011;
    input imm12;
    input [4:0] rd;
    input [4:0] imm62;
    begin
      c1_011 = {3'b011, imm12, rd, imm62, 2'b01};
    end
  endfunction

  function [31:0] fetch_word;
    input integer c;
    reg [15:0] lo;
    reg [15:0] hi;
    begin
      case (c % 12)
        0: lo = c1_011(1'b0, 5'h02, 5'h00); // exact changed zero branch
        1: lo = c1_011(1'b1, 5'h02, 5'h00); // bit 12 nonzero
        2: lo = c1_011(1'b0, 5'h02, 5'h01); // bit 2 nonzero
        3: lo = c1_011(1'b0, 5'h03, 5'h00); // c.lui illegal zero path
        4: lo = 16'h0001; // c.nop
        5: lo = 16'h6105; // c.addi16sp with nzimm bit set
        6: lo = 16'h7101; // c.addi16sp with sign bit set
        7: lo = 16'h6141;
        8: lo = 16'h6181;
        9: lo = 16'h8002;
        10: lo = 16'h9002;
        default: lo = 16'h0000;
      endcase
      hi = c1_011(c & 1, (5'h02 + (c & 31)) & 31, ((c >> 1) & 31) ^ 5'h0d);
      fetch_word = {hi, lo};
    end
  endfunction

  task drive_cycle(input integer c);
    begin
      req_i = (c > 2);
      id_ready_i = ((c % 9) != 3);
      clear_instr_valid_i = ((c % 31) == 11);
      instr_gnt_i = ((c % 5) != 1);
      instr_rvalid_i = ((c % 4) != 2) || ((c >= 45) && (c <= 60));
      instr_rdata_i = fetch_word(c);
      instr_err_i = (c == 77);
      instr_err_pmp_i = (c == 118);
      pc_set_i = (c == 0) || (c == 36) || (c == 102);
      pc_mux_i = (c == 36) ? 4'b0010 : 4'b0000;
      jump_target_id_i = 32'h0000_2000 + (c << 2);
      jump_target_ex_i = 32'h0000_3000 + (c << 2);
      hwlp_jump_i = (c == 83);
      hwlp_target_i = 32'h0000_4000 + (c << 1);
      halt_if_i = ((c % 43) == 17);
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    rst_n = 1'b0;
    m_trap_base_addr_i = 24'h000080;
    u_trap_base_addr_i = 24'h000090;
    trap_addr_mux_i = 2'b00;
    boot_addr_i = 32'h0000_1000;
    dm_exception_addr_i = 32'h0000_0100;
    dm_halt_addr_i = 32'h0000_0180;
    req_i = 1'b0;
    instr_gnt_i = 1'b0;
    instr_rvalid_i = 1'b0;
    instr_rdata_i = 32'b0;
    instr_err_i = 1'b0;
    instr_err_pmp_i = 1'b0;
    clear_instr_valid_i = 1'b0;
    pc_set_i = 1'b0;
    mepc_i = 32'h0000_8000;
    uepc_i = 32'h0000_9000;
    depc_i = 32'h0000_a000;
    pc_mux_i = 4'b0000;
    exc_pc_mux_i = 3'b000;
    m_exc_vec_pc_mux_i = 5'b0;
    u_exc_vec_pc_mux_i = 5'b0;
    jump_target_id_i = 32'b0;
    jump_target_ex_i = 32'b0;
    hwlp_jump_i = 1'b0;
    hwlp_target_i = 32'b0;
    halt_if_i = 1'b0;
    id_ready_i = 1'b0;
    repeat (6) @(negedge clk);
    rst_n = 1'b1;
    for (cycle = 0; cycle < 220; cycle = cycle + 1) begin
      @(negedge clk);
      drive_cycle(cycle);
      @(posedge clk);
      #1;
      $display("C,%0d,%b,%h,%b,%b,%h,%h,%h,%b,%b,%b,%b",
        cycle,
        instr_valid_id_o,
        instr_rdata_id_o,
        is_compressed_id_o,
        illegal_c_insn_id_o,
        pc_if_o,
        pc_id_o,
        instr_addr_o,
        instr_req_o,
        if_busy_o,
        perf_imiss_o,
        csr_mtvec_init_o);
    end
    $finish;
  end
endmodule
"""


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def sha(path: Path) -> str:
    return subprocess.check_output(["sha256sum", str(path)], text=True).split()[0]


def simulate(label: str, bundle: Path) -> dict[str, object]:
    side = OUT / label
    if side.exists():
        shutil.rmtree(side)
    side.mkdir(parents=True)
    tb = side / "tb.sv"
    tb.write_text(TB.strip() + "\n")
    exe = side / "simv"
    proc = run([str(IVERILOG), "-g2012", "-s", "tb", "-o", str(exe), str(bundle), str(tb)], side)
    (side / "compile.stdout").write_text(proc.stdout)
    (side / "compile.stderr").write_text(proc.stderr)
    if proc.returncode != 0:
        raise RuntimeError(f"{label}: iverilog failed: {proc.stderr[-1600:]}")
    proc = run([str(VVP), str(exe)], side)
    (side / "sim.stdout").write_text(proc.stdout)
    (side / "sim.stderr").write_text(proc.stderr)
    if proc.returncode != 0:
        raise RuntimeError(f"{label}: vvp failed: {proc.stderr[-1600:]}")
    rows = [line for line in proc.stdout.splitlines() if line.startswith("C,")]
    return {
        "bundle_sha256": sha(bundle),
        "rows": rows,
        "sim_log_sha256": sha(side / "sim.stdout"),
        "vcd": side / "wave.vcd",
    }


def parse_vcd(path: Path) -> dict[str, int]:
    text = path.read_text(errors="replace")
    id_to_scope: dict[str, str] = {}
    scope: list[str] = []
    for line in text.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[0] == "$scope":
            scope.append(parts[2])
        elif len(parts) >= 2 and parts[0] == "$upscope":
            if scope:
                scope.pop()
        elif len(parts) >= 5 and parts[0] == "$var":
            ident = parts[3]
            name = parts[4]
            id_to_scope[ident] = ".".join([*scope, name])
        elif line == "$enddefinitions $end":
            break

    values: dict[str, str] = {}
    toggles: dict[str, int] = {name: 0 for name in id_to_scope.values()}
    for line in text.splitlines():
        if not line or line[0] in "#$":
            continue
        if line[0] in "01xz":
            ident = line[1:]
            value = line[0]
        elif line[0] in "bBrR":
            m = re.match(r"[bBrR]([01xzXZ]+)\s+(.+)", line)
            if not m:
                continue
            value, ident = m.group(1), m.group(2)
        else:
            continue
        name = id_to_scope.get(ident)
        if not name:
            continue
        old = values.get(ident)
        if old is not None and old != value:
            toggles[name] += sum(a != b for a, b in zip(old.zfill(len(value)), value.zfill(len(old)))) or 1
        values[ident] = value
    return toggles


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    gold = simulate("gold", GOLD)
    gate = simulate("gate", GATE)
    boundary_equal = gold["rows"] == gate["rows"]
    gold_toggles = parse_vcd(gold["vcd"])
    gate_toggles = parse_vcd(gate["vcd"])
    common = sorted(set(gold_toggles) & set(gate_toggles))
    common_gold = sum(gold_toggles[name] for name in common)
    common_gate = sum(gate_toggles[name] for name in common)
    with gzip.open(OUT / "gold.vcd.gz", "wb") as f:
        f.write(gold["vcd"].read_bytes())
    with gzip.open(OUT / "gate.vcd.gz", "wb") as f:
        f.write(gate["vcd"].read_bytes())
    exercise = {
        name: gate_toggles[name]
        for name in sorted(gate_toggles)
        if "compressed" in name
        or "illegal" in name
        or "instr_aligned" in name
        or "instr_decompressed" in name
    }
    result = {
        "boundary_equality_every_cycle": boundary_equal,
        "candidate": "compressed_l244_addi16sp_lui_zero_reduce",
        "common_paths": len(common),
        "common_toggles": {"gold": common_gold, "gate": common_gate},
        "cycle_count": len(gold["rows"]),
        "gate_bundle_sha256": gate["bundle_sha256"],
        "gate_vcd_gzip_sha256": sha(OUT / "gate.vcd.gz"),
        "gold_bundle_sha256": gold["bundle_sha256"],
        "gold_vcd_gzip_sha256": sha(OUT / "gold.vcd.gz"),
        "toggle_delta_pct_common_paths": ((common_gate - common_gold) / common_gold * 100) if common_gold else None,
        "exercise_sample": exercise,
        "tools": {"iverilog": str(IVERILOG), "vvp": str(VVP)},
    }
    (OUT / "toggle_convention_receipt.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    failures = []
    expected = json.loads((PACKAGE / "activity/toggle_convention_receipt.json").read_text())
    for key in ("candidate", "cycle_count"):
        if result[key] != expected[key]:
            failures.append(f"{key} differs from packaged receipt: {result[key]!r} != {expected[key]!r}")
    if result["common_toggles"] != expected["common_toggles"]:
        failures.append("common toggles differ from packaged receipt")
    if not boundary_equal:
        failures.append("gold/gate boundary rows differ")
    if failures:
        raise SystemExit("\n".join(failures))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
