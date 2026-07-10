#!/usr/bin/env python3
from __future__ import annotations

import gzip
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GOLD = ROOT / "gold_prefetch_buffer_parent.v"
GATE = ROOT / "gate_prefetch_buffer_parent.v"
OUT = Path(os.environ.get("OUT_DIR", "/tmp/cv32-prefetch-activity"))
IVERILOG = Path(os.environ.get("IVERILOG", "/workdir/_tools/oss-cad-suite-20260630/bin/iverilog"))
VVP = Path(os.environ.get("VVP", "/workdir/_tools/oss-cad-suite-20260630/bin/vvp"))
CANDIDATE = "prefetch_hwlp_plus_next_cnt_arith"

TB = r"""
`timescale 1ns/1ps
module tb;
  reg clk;
  reg rst_n;
  reg req_i;
  reg branch_i;
  reg [31:0] branch_addr_i;
  reg hwlp_jump_i;
  reg [31:0] hwlp_target_i;
  reg fetch_ready_i;
  wire fetch_valid_o;
  wire [31:0] fetch_rdata_o;
  wire instr_req_o;
  reg instr_gnt_i;
  wire [31:0] instr_addr_o;
  reg [31:0] instr_rdata_i;
  reg instr_rvalid_i;
  reg instr_err_i;
  reg instr_err_pmp_i;
  wire busy_o;

  cv32e40p_prefetch_buffer dut (
    .clk(clk),
    .rst_n(rst_n),
    .req_i(req_i),
    .branch_i(branch_i),
    .branch_addr_i(branch_addr_i),
    .hwlp_jump_i(hwlp_jump_i),
    .hwlp_target_i(hwlp_target_i),
    .fetch_ready_i(fetch_ready_i),
    .fetch_valid_o(fetch_valid_o),
    .fetch_rdata_o(fetch_rdata_o),
    .instr_req_o(instr_req_o),
    .instr_gnt_i(instr_gnt_i),
    .instr_addr_o(instr_addr_o),
    .instr_rdata_i(instr_rdata_i),
    .instr_rvalid_i(instr_rvalid_i),
    .instr_err_i(instr_err_i),
    .instr_err_pmp_i(instr_err_pmp_i),
    .busy_o(busy_o)
  );

  integer cycle;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task drive_cycle(input integer c);
    begin
      req_i = (c > 3);
      fetch_ready_i = ((c % 5) != 2);
      instr_gnt_i = ((c % 4) != 1);
      instr_rvalid_i = ((c % 7) == 0) || ((c % 11) == 3) || ((c >= 30) && (c < 42) && ((c % 3) == 0));
      branch_i = (c == 26) || (c == 96) || (c == 181);
      hwlp_jump_i = (c == 34) || (c == 35) || (c == 66) || (c == 67) || (c == 68) || (c == 142) || (c == 143) || (c == 211);
      branch_addr_i = 32'h1000_0000 + (c << 2);
      hwlp_target_i = 32'h2000_0000 + (c << 2);
      instr_rdata_i = 32'hA500_0000 ^ (c * 32'h0001_0101);
      instr_err_i = (c == 137);
      instr_err_pmp_i = (c == 173);
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    rst_n = 1'b0;
    req_i = 1'b0;
    branch_i = 1'b0;
    branch_addr_i = 32'b0;
    hwlp_jump_i = 1'b0;
    hwlp_target_i = 32'b0;
    fetch_ready_i = 1'b0;
    instr_gnt_i = 1'b0;
    instr_rdata_i = 32'b0;
    instr_rvalid_i = 1'b0;
    instr_err_i = 1'b0;
    instr_err_pmp_i = 1'b0;
    for (cycle = 0; cycle < 6; cycle = cycle + 1) begin
      @(negedge clk);
    end
    rst_n = 1'b1;
    for (cycle = 0; cycle < 260; cycle = cycle + 1) begin
      @(negedge clk);
      drive_cycle(cycle);
      @(posedge clk);
      #1;
      $display("C,%0d,%b,%h,%b,%h,%b", cycle, fetch_valid_o, fetch_rdata_o, instr_req_o, instr_addr_o, busy_o);
    end
    $finish;
  end
endmodule
"""


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def sha(path: Path) -> str:
    return subprocess.check_output(["sha256sum", str(path)], text=True).split()[0]


def simulate(label: str, bundle: Path) -> dict:
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
        raise RuntimeError(f"{label}: iverilog failed: {proc.stderr[-1200:]}")
    proc = run([str(VVP), str(exe)], side)
    (side / "sim.stdout").write_text(proc.stdout)
    (side / "sim.stderr").write_text(proc.stderr)
    if proc.returncode != 0:
        raise RuntimeError(f"{label}: vvp failed: {proc.stderr[-1200:]}")
    rows = [line for line in proc.stdout.splitlines() if line.startswith("C,")]
    return {
        "bundle_sha": sha(bundle),
        "rows": rows,
        "sim_log_sha": sha(side / "sim.stdout"),
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
            id_to_scope[parts[3]] = ".".join([*scope, parts[4]])
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
    with gzip.GzipFile(filename="", mode="wb", fileobj=(OUT / "gold.vcd.gz").open("wb"), mtime=0) as f:
        f.write(gold["vcd"].read_bytes())
    with gzip.GzipFile(filename="", mode="wb", fileobj=(OUT / "gate.vcd.gz").open("wb"), mtime=0) as f:
        f.write(gate["vcd"].read_bytes())
    result = {
        "boundary_equality_every_cycle": boundary_equal,
        "candidate": CANDIDATE,
        "common_paths": len(common),
        "common_toggles": {"gold": common_gold, "gate": common_gate},
        "cycle_count": len(gold["rows"]),
        "gold_bundle_sha": gold["bundle_sha"],
        "gate_bundle_sha": gate["bundle_sha"],
        "gold_vcd_gzip_sha": sha(OUT / "gold.vcd.gz"),
        "gate_vcd_gzip_sha": sha(OUT / "gate.vcd.gz"),
        "toggle_delta_pct_common_paths": ((common_gate - common_gold) / common_gold * 100) if common_gold else None,
        "exercise_sample": {
            name: gate_toggles[name]
            for name in sorted(gate_toggles)
            if "cnt" in name.lower()
            or "hwlp" in name.lower()
            or "flush" in name.lower()
            or "resp_valid" in name
            or "fifo_empty" in name
        },
    }
    (OUT / "toggle_convention_receipt.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if boundary_equal else 1


if __name__ == "__main__":
    raise SystemExit(main())
