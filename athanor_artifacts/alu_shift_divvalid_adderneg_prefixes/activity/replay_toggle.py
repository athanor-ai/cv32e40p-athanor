#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

PACKAGE = Path(__file__).resolve().parents[1]
GOLD = PACKAGE / "gold_alu_parent_context.v"
GATE = PACKAGE / "gate_alu_parent_context.v"
TOP = "cv32e40p_alu_parent_context"
OUT = Path(os.environ.get("OUT_DIR", "/tmp/cv32-alu-shift-divvalid-adderneg-activity-replay"))
CYCLES = 1400
SEED = 0xA11D1EAF


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def sha_vcd_norm(path: Path) -> str:
    h = hashlib.sha256()
    skipping = False
    for line in path.read_text(errors="ignore").splitlines(True):
        s = line.strip()
        if s.startswith("$date"):
            skipping = True
        if not skipping:
            h.update(line.encode())
        if skipping and s.endswith("$end"):
            skipping = False
    return h.hexdigest()


def modules(text: str) -> dict[str, str]:
    ms = list(re.finditer(r"(?m)^module\s+(\w+)\s*(?:#\s*\(|\()", text))
    out: dict[str, str] = {}
    for i, m in enumerate(ms):
        end = ms[i + 1].start() if i + 1 < len(ms) else len(text)
        out[m.group(1)] = text[m.start() : end]
    return out


def prefix_design(text: str, prefix: str, module_names: list[str]) -> str:
    for name in sorted(module_names, key=len, reverse=True):
        text = re.sub(rf"(?m)^module\s+{re.escape(name)}\b", f"module {prefix}{name}", text)
    for name in sorted(module_names, key=len, reverse=True):
        text = re.sub(
            rf"(?m)(^\s*){re.escape(name)}(\s+(?:#\s*\(|[A-Za-z_\\]))",
            rf"\1{prefix}{name}\2",
            text,
        )
    return text


def parse_ports(top_text: str) -> tuple[list[tuple[str, str, int]], list[tuple[str, str, int]]]:
    ports: list[tuple[str, str, int]] = []
    # Handles sv2v's ANSI-ish parent wrapper declaration.
    for m in re.finditer(
        r"(?m)^\s*(input|output)\s+(?:wire\s+|reg\s+)?(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_][A-Za-z0-9_]*)\s*,?",
        top_text,
    ):
        direction, hi, lo, name = m.groups()
        width = abs(int(hi) - int(lo)) + 1 if hi else 1
        ports.append((direction, name, width))
    inputs = [p for p in ports if p[0] == "input"]
    outputs = [p for p in ports if p[0] == "output"]
    if not inputs or not outputs:
        raise RuntimeError("failed to parse ALU parent ports")
    return inputs, outputs


def lcg(x: int) -> int:
    return (x * 1664525 + 1013904223) & 0xFFFFFFFF


OPS = [
    0b0110000,  # DIVU
    0b0110001,  # DIV
    0b0110010,  # REMU
    0b0110011,  # REM
    0b0011000,  # ADD
    0b0011001,  # SUB
    0b0100110,  # SLL
    0b0100111,  # SRL
    0b0001100,  # EQ
]


def build_trace(inputs: list[tuple[str, str, int]]) -> list[dict[str, int]]:
    seed = SEED
    rows: list[dict[str, int]] = []
    div_ops = OPS[:4]
    for cycle in range(CYCLES):
        seed = lcg(seed ^ ((cycle * 0x9E3779B9) & 0xFFFFFFFF))
        row: dict[str, int] = {}
        if cycle % 5 in (0, 1, 2, 3):
            op = div_ops[(cycle // 5 + cycle) % len(div_ops)]
        else:
            op = OPS[(cycle // 5) % len(OPS)]
        for _, name, width in inputs:
            if name in ("clk", "rst_n"):
                continue
            if name == "ex_ready_i":
                value = 1
            elif name == "alu_en_i":
                value = 1 if cycle % 7 != 6 else 0
            elif name == "alu_operator_i":
                value = op
            elif name == "alu_operand_a_i":
                value = seed ^ (cycle * 0x01010101)
            elif name == "alu_operand_b_i":
                value = (lcg(seed) | 1) & 0xFFFFFFFF
            elif name == "alu_operand_c_i":
                value = lcg(seed ^ 0xC001D00D)
            elif name == "alu_vec_mode_i":
                value = [0b00, 0b10, 0b11, 0b00][cycle % 4]
            elif name == "bmask_a_i":
                value = (cycle * 3 + 1) & 0x1F
            elif name == "bmask_b_i":
                value = (cycle * 5 + 2) & 0x1F
            elif name == "imm_vec_ext_i":
                value = cycle & 0x3
            elif name == "alu_is_clpx_i":
                value = 1 if cycle % 37 == 0 else 0
            elif name == "alu_is_subrot_i":
                value = 1 if cycle % 41 == 0 else 0
            elif name == "alu_clpx_shift_i":
                value = (cycle >> 2) & 0x3
            elif name == "regfile_alu_we_i":
                value = 1 if cycle % 3 != 0 else 0
            elif name == "regfile_alu_waddr_i":
                value = (cycle * 7) & 0x3F
            elif name == "csr_access_i":
                value = 1 if cycle % 29 == 0 else 0
            elif name == "csr_rdata_i":
                value = seed ^ 0x5A5AA5A5
            else:
                value = seed & ((1 << width) - 1)
            row[name] = value & ((1 << width) - 1)
        rows.append(row)
    return rows


def decl(kind: str, name: str, width: int) -> str:
    if width == 1:
        return f"  {kind} {name};"
    return f"  {kind} [{width - 1}:0] {name};"


def make_tb(inputs: list[tuple[str, str, int]], outputs: list[tuple[str, str, int]], trace: list[dict[str, int]]) -> str:
    lines = ["`timescale 1ns/1ps", "module tb;", "  reg clk = 1'b0;", "  reg rst_n = 1'b0;"]
    for _, name, width in inputs:
        if name in ("clk", "rst_n"):
            continue
        lines.append(decl("reg", name, width).replace(";", " = '0;"))
    for side in ("gold", "gate"):
        for _, name, width in outputs:
            lines.append(decl("wire", f"{side}_{name}", width))
    total = sum(width for _, _, width in outputs)
    for side in ("gold", "gate"):
        cat = ", ".join(f"{side}_{name}" for _, name, _ in outputs)
        lines.append(f"  wire [{total - 1}:0] {side}_vec = {{ {cat} }};")

    def inst(mod: str, side: str) -> str:
        conns = []
        for _, name, _ in inputs:
            conns.append(f".{name}({name})")
        for _, name, _ in outputs:
            conns.append(f".{name}({side}_{name})")
        return f"  {mod} {side} (\n    " + ",\n    ".join(conns) + "\n  );"

    lines.append(inst("gold_" + TOP, "gold"))
    lines.append(inst("gate_" + TOP, "gate"))
    lines.append("  always #5 clk = ~clk;")
    lines.append("  task apply_cycle(input integer cycle); begin")
    lines.append("    case (cycle)")
    for idx, row in enumerate(trace):
        lines.append(f"      {idx}: begin")
        for _, name, width in inputs:
            if name in ("clk", "rst_n"):
                continue
            lines.append(f"        {name} = {width}'h{row[name]:x};")
        lines.append("      end")
    lines.append("    endcase")
    lines.append("  end endtask")
    lines.append("  integer cycle;")
    lines.append("  initial begin")
    lines.append('    $dumpfile("toggle.vcd");')
    lines.append("    $dumpvars(0, tb.gold);")
    lines.append("    $dumpvars(0, tb.gate);")
    lines.append("    repeat (6) @(posedge clk);")
    lines.append("    rst_n = 1'b1;")
    lines.append("    repeat (4) @(posedge clk);")
    lines.append(f"    for (cycle = 0; cycle < {CYCLES}; cycle = cycle + 1) begin")
    lines.append("      @(negedge clk);")
    lines.append("      apply_cycle(cycle);")
    lines.append("      @(posedge clk); #1;")
    lines.append("      if (gold_vec !== gate_vec) begin")
    lines.append('        $display("MISMATCH cycle=%0d gold=%h gate=%h", cycle, gold_vec, gate_vec);')
    lines.append("        $fatal(1);")
    lines.append("      end")
    lines.append("    end")
    lines.append('    $display("cv32 alu activity replay completed cycles=%0d", cycle);')
    lines.append("    $finish;")
    lines.append("  end")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


def normalize(value: str, width: int) -> str | None:
    value = value.lower()
    if any(ch not in "01" for ch in value):
        return None
    return value.zfill(width)[-width:]


def count_vcd(path: Path) -> dict[str, object]:
    scopes: list[str] = []
    in_defs = True
    id_maps: dict[str, list[tuple[str, str, int]]] = {}
    prev: dict[tuple[str, str], str] = {}
    widths: dict[tuple[str, str], int] = {}
    path_owners: dict[str, set[str]] = {}
    counts = {"gold": 0, "gate": 0}
    exercise: dict[str, int] = {}
    for raw in path.read_text(errors="ignore").splitlines():
        line = raw.strip()
        if not line:
            continue
        if in_defs:
            if line.startswith("$scope"):
                parts = line.split()
                if len(parts) >= 3:
                    scopes.append(parts[2])
            elif line.startswith("$upscope"):
                if scopes:
                    scopes.pop()
            elif line.startswith("$var"):
                parts = line.split()
                if len(parts) >= 5:
                    owner = None
                    if len(scopes) >= 2 and scopes[0] == "tb" and scopes[1] in ("gold", "gate"):
                        owner = scopes[1]
                    if owner:
                        ident = parts[3]
                        name = parts[4]
                        canon = ".".join(scopes[2:] + [name])
                        width = int(parts[2])
                        id_maps.setdefault(ident, []).append((owner, canon, width))
                        path_owners.setdefault(canon, set()).add(owner)
                        widths[(owner, canon)] = width
            elif line.startswith("$enddefinitions"):
                in_defs = False
            continue
        if line[0] in "01xz":
            ident = line[1:]
            rawval = line[0]
        elif line[0] in "bBrR":
            parts = line.split()
            if len(parts) != 2:
                continue
            rawval = parts[0][1:]
            ident = parts[1]
        else:
            continue
        mappings = id_maps.get(ident)
        if not mappings:
            continue
        for owner, canon, width in mappings:
            if path_owners.get(canon) != {"gold", "gate"}:
                continue
            if widths.get(("gold", canon)) != widths.get(("gate", canon)):
                continue
            value = normalize(rawval, width)
            if value is None:
                prev.pop((owner, canon), None)
                continue
            old = prev.get((owner, canon))
            if old is not None:
                flips = sum(a != b for a, b in zip(old, value))
                counts[owner] += flips
                if owner == "gold" and any(k in canon for k in ("alu_operator_i", "div_valid", "alu_i.alu_div_i", "alu_ready_o", "regfile_alu_wdata_fw_o")):
                    exercise[canon] = exercise.get(canon, 0) + flips
            prev[(owner, canon)] = value
    common_paths = 0
    for canon, owners in path_owners.items():
        if owners == {"gold", "gate"} and widths.get(("gold", canon)) == widths.get(("gate", canon)):
            common_paths += 1
    return {
        "common_toggles": counts,
        "common_paths": common_paths,
        "exercise": dict(sorted(exercise.items())[:80]),
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    work = OUT / "work"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir()
    gm = modules(GOLD.read_text())
    tm = modules(GATE.read_text())
    names = list(gm.keys())
    if TOP not in gm or TOP not in tm:
        raise SystemExit("top missing")
    (work / "gold_design.v").write_text(prefix_design(GOLD.read_text(), "gold_", names))
    (work / "gate_design.v").write_text(prefix_design(GATE.read_text(), "gate_", names))
    inputs, outputs = parse_ports(gm[TOP])
    trace = build_trace(inputs)
    (OUT / "toggle_trace.json").write_text(json.dumps(trace, indent=2) + "\n")
    (work / "tb.v").write_text(make_tb(inputs, outputs, trace))
    iverilog = os.environ.get("IVERILOG", "/workdir/_tools/oss-cad-suite-20260630/bin/iverilog")
    vvp = os.environ.get("VVP", "/workdir/_tools/oss-cad-suite-20260630/bin/vvp")
    cp = subprocess.run([iverilog, "-g2012", "-o", "simv", "gold_design.v", "gate_design.v", "tb.v"], cwd=work, text=True, capture_output=True)
    log = cp.stdout + cp.stderr
    if cp.returncode:
        (OUT / "toggle_sim.log").write_text(log)
        raise SystemExit(log)
    sp = subprocess.run([vvp, "simv"], cwd=work, text=True, capture_output=True)
    log += sp.stdout + sp.stderr
    (OUT / "toggle_sim.log").write_text(log)
    if sp.returncode:
        raise SystemExit(log)
    shutil.copy2(work / "toggle.vcd", OUT / "toggle.vcd")
    counts = count_vcd(OUT / "toggle.vcd")
    gold = counts["common_toggles"]["gold"]
    gate = counts["common_toggles"]["gate"]
    delta = 0.0 if gold == 0 else (gate - gold) / gold * 100.0
    receipt = {
        "candidate": "alu_shift_divvalid_adderneg_prefixes",
        "top": TOP,
        "scope": "alu_parent_context_activity_proxy_not_full_core_power_claim",
        "cycles": CYCLES,
        "stimulus": "div_rem_heavy_alu_parent_trace",
        "boundary_equality_every_cycle": True,
        "gold_sha256": sha(GOLD),
        "gate_sha256": sha(GATE),
        "trace_sha256": sha(OUT / "toggle_trace.json"),
        "vcd_sha256": sha(OUT / "toggle.vcd"),
        "normalized_vcd_sha256": sha_vcd_norm(OUT / "toggle.vcd"),
        "sim_log_sha256": sha(OUT / "toggle_sim.log"),
        "common_toggles": counts["common_toggles"],
        "common_paths": counts["common_paths"],
        "toggle_delta_pct_common_paths": round(delta, 6),
        "toggle_status": "neutral_or_better" if gate <= gold else "regression",
        "exercise_sample": counts["exercise"],
    }
    (OUT / "toggle_convention_receipt.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    expected = json.loads((Path(__file__).resolve().parent / "toggle_convention_receipt.json").read_text())
    checked_fields = [
        "candidate",
        "top",
        "scope",
        "cycles",
        "stimulus",
        "boundary_equality_every_cycle",
        "gold_sha256",
        "gate_sha256",
        "common_toggles",
        "toggle_delta_pct_common_paths",
        "toggle_status",
    ]
    mismatches = [
        f"{field}: replay={receipt[field]!r} packaged={expected[field]!r}"
        for field in checked_fields
        if receipt[field] != expected[field]
    ]
    for key in ("alu_i.div_valid", "alu_operator_i", "alu_ready_o", "regfile_alu_wdata_fw_o"):
        if receipt["exercise_sample"].get(key) != expected["exercise_sample"].get(key):
            mismatches.append(
                f"exercise_sample.{key}: replay={receipt['exercise_sample'].get(key)!r} packaged={expected['exercise_sample'].get(key)!r}"
            )
    if receipt["common_paths"] <= 0:
        mismatches.append(f"common_paths: replay found no comparable gold/gate VCD paths")
    if mismatches:
        raise SystemExit("activity replay mismatches packaged receipt:\n" + "\n".join(mismatches))
    print(json.dumps(receipt, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
