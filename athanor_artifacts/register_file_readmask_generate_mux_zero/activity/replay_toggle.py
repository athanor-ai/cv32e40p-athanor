#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, re, shutil, subprocess, sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parents[1]
GOLD = PACKAGE / 'gold_split_context_default.v'
GATE = PACKAGE / 'gate_split_context_default.v'
TOP = 'cv32e40p_id_ex_readmask_context'
OUT = Path(os.environ.get('OUT_DIR', str(PACKAGE / 'replay_out' / 'activity')))
CYCLES = 750
SEED = 0x5eed3241

def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()

def sha_vcd_norm(path: Path) -> str:
    h = hashlib.sha256(); skipping = False
    for line in path.read_text(errors='ignore').splitlines(True):
        s = line.strip()
        if s.startswith('$date'): skipping = True
        if not skipping: h.update(line.encode())
        if skipping and s.endswith('$end'): skipping = False
    return h.hexdigest()

def modules(text: str) -> dict[str,str]:
    ms = list(re.finditer(r'(?m)^module\s+(\w+)\s*\(', text))
    out = {}
    for i,m in enumerate(ms):
        end = ms[i+1].start() if i+1 < len(ms) else len(text)
        out[m.group(1)] = text[m.start():end]
    return out

def prefix_design(text: str, prefix: str, module_names: list[str]) -> str:
    # Rename module declarations and cell instantiation types for the small sv2v bundle.
    for name in sorted(module_names, key=len, reverse=True):
        text = re.sub(rf'(?m)^module\s+{re.escape(name)}\b', f'module {prefix}{name}', text)
    for name in sorted(module_names, key=len, reverse=True):
        text = re.sub(rf'(?m)(^\s*){re.escape(name)}(\s+(?:#\s*\(|[A-Za-z_\\]))', rf'\1{prefix}{name}\2', text)
    return text

def parse_ports(top_text: str):
    ports=[]
    header = top_text.split(');', 1)[0]
    header_names = set(re.findall(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$', header, re.M))
    for m in re.finditer(r'(?m)^\s*(input|output)\s+(?:wire\s+|reg\s+)?(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_][A-Za-z0-9_]*)\s*;', top_text):
        d, hi, lo, name = m.groups()
        if name not in header_names:
            continue
        width = abs(int(hi)-int(lo))+1 if hi else 1
        ports.append((d, name, width))
    if not ports:
        raise SystemExit('no ports parsed')
    return ports

def lcg(x): return (x * 1664525 + 1013904223) & 0xffffffff

def rtype(funct7: int, rs2: int, rs1: int, funct3: int, rd: int, opcode: int = 0x33) -> int:
    return ((funct7 & 0x7f) << 25) | ((rs2 & 0x1f) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1f) << 7) | (opcode & 0x7f)

def itype(imm: int, rs1: int, funct3: int, rd: int, opcode: int = 0x13) -> int:
    return ((imm & 0xfff) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1f) << 7) | (opcode & 0x7f)

def stype(imm: int, rs2: int, rs1: int, funct3: int = 2, opcode: int = 0x23) -> int:
    return (((imm >> 5) & 0x7f) << 25) | ((rs2 & 0x1f) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 7) << 12) | ((imm & 0x1f) << 7) | (opcode & 0x7f)

def btype(imm: int, rs2: int, rs1: int, funct3: int = 0, opcode: int = 0x63) -> int:
    imm &= 0x1fff
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3f) << 25) | ((rs2 & 0x1f) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 7) << 12) | (((imm >> 1) & 0xf) << 8) | (((imm >> 11) & 1) << 7) | (opcode & 0x7f)

def id_instr(c: int) -> int:
    rd = (c * 7 + 3) % 31 + 1
    rs1 = (c * 5 + 1) % 31 + 1
    rs2 = (c * 11 + 2) % 31 + 1
    sel = c % 10
    if sel == 0:
        return rtype(0, rs2, rs1, 0, rd)       # add
    if sel == 1:
        return rtype(0x20, rs2, rs1, 0, rd)    # sub
    if sel == 2:
        return rtype(0, rs2, rs1, 7, rd)       # and
    if sel == 3:
        return rtype(0, rs2, rs1, 6, rd)       # or
    if sel == 4:
        return itype((c * 13) & 0xfff, rs1, 0, rd)
    if sel == 5:
        return itype((c * 9) & 0xfff, rs1, 2, rd)  # slti
    if sel == 6:
        return itype((c * 4) & 0xfff, rs1, 2, rd, 0x03)  # lw
    if sel == 7:
        return stype((c * 4) & 0xfff, rs2, rs1)
    if sel == 8:
        return btype((c % 32) * 2, rs2, rs1)
    return itype((c * 4) & 0xfff, rs1, 0, rd, 0x67)  # jalr

def trace(inputs):
    seed = SEED
    valid = [31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,11,3,7]
    tr=[]
    for c in range(CYCLES):
        row={}
        # Interrupt-rich deterministic pattern. Keep valid IRQ mask bits active and rotate priority.
        bit = valid[c % len(valid)]
        irq = 1 << bit
        if c % 7 == 0: irq |= 1 << valid[(c//7) % len(valid)]
        if c % 11 == 0: irq |= 1 << valid[(c//11 + 5) % len(valid)]
        mie = (1 << bit) | (1 << valid[(c*3 + 2) % len(valid)]) | (1 << 11) | (1 << 3) | (1 << 7)
        for name,width in inputs:
            if name in ('clk','clk_ungated_i','rst_n'):
                continue
            if name == 'irq_i': val = irq
            elif name == 'mie_bypass_i': val = mie
            elif name == 'm_irq_enable_i': val = 1
            elif name == 'u_irq_enable_i': val = 0
            elif name == 'irq_sec_i': val = (c >> 2) & 1
            elif name == 'current_priv_lvl_i': val = 3  # PRIV_LVL_M
            elif name == 'instr_rdata_i':
                val = id_instr(c)
            elif name == 'pc_id_i':
                val = 0x10000000 + 4 * c
            elif name == 'regfile_waddr_wb_i':
                val = (c * 3 + 1) % 31 + 1
            elif name == 'regfile_alu_waddr_fw_i':
                val = (c * 5 + 7) % 31 + 1
            elif name == 'regfile_wdata_wb_i':
                seed = lcg(seed ^ 0x13579bdf); val = seed ^ (c * 0x10204081)
            elif name == 'regfile_alu_wdata_fw_i':
                seed = lcg(seed ^ 0x2468ace0); val = seed ^ (c * 0x01010101)
            elif name in ('regfile_we_wb_i','regfile_we_wb_power_i'):
                val = 1 if (c % 4) != 0 else 0
            elif name in ('regfile_alu_we_fw_i','regfile_alu_we_fw_power_i'):
                val = 1 if (c % 5) in (1, 2, 3) else 0
            elif name in ('ex_ready_i','wb_ready_i','fetch_enable_i','instr_valid_i'):
                val = 1
            elif name in ('is_compressed_i','illegal_c_insn_i','fs_off_i','apu_read_dep_i','apu_read_dep_for_jalr_i','apu_write_dep_i','apu_busy_i','mult_multicycle_i','perf_imiss_i'):
                val = 0
            elif name in ('debug_req_i','debug_single_step_i','debug_ebreakm_i','debug_ebreaku_i','trigger_match_i','is_fetch_failed_i','data_err_i','data_misaligned_i'):
                val = 0
            elif name == 'mcounteren_i':
                val = (1 << width) - 1
            else:
                seed = lcg(seed ^ ((c + width) * 0x9e3779b9 & 0xffffffff))
                if width == 1:
                    val = (seed >> 31) & 1
                else:
                    v = 0
                    for _ in range((width + 31)//32):
                        seed = lcg(seed); v = (v << 32) | seed
                    val = v & ((1 << width)-1)
            row[name] = val & ((1 << width)-1)
        tr.append(row)
    return tr

def make_tb(inputs, outputs, tr):
    lines=['`timescale 1ns/1ps','module tb;','  reg clk = 1\'b0;','  reg clk_ungated_i = 1\'b0;','  reg rst_n = 1\'b0;']
    for _,name,width in inputs:
        if name in ('clk','clk_ungated_i','rst_n'): continue
        lines.append(f"  reg [{width-1}:0] {name} = {width}'d0;" if width>1 else f"  reg {name} = 1'b0;")
    for side in ('gold','gate'):
        for _,name,width in outputs:
            lines.append(f"  wire [{width-1}:0] {side}_{name};" if width>1 else f"  wire {side}_{name};")
    total=sum(w for _,_,w in outputs)
    for side in ('gold','gate'):
        cat=', '.join(f'{side}_{name}' for _,name,_ in outputs)
        lines.append(f'  wire [{total-1}:0] {side}_vec = {{ {cat} }};')
    def inst(mod, side):
        conns=[]
        for _,name,_ in inputs: conns.append(f'.{name}({name})')
        for _,name,_ in outputs: conns.append(f'.{name}({side}_{name})')
        return f"  {mod} {side} (\n    " + ',\n    '.join(conns) + '\n  );'
    lines.append(inst('gold_'+TOP, 'gold'))
    lines.append(inst('gate_'+TOP, 'gate'))
    lines.append('  always #5 begin clk = ~clk; clk_ungated_i = clk; end')
    lines.append('  task apply_cycle(input integer c); begin')
    lines.append('    case (c)')
    for i,row in enumerate(tr):
        lines.append(f'      {i}: begin')
        for _,name,width in inputs:
            if name in ('clk','clk_ungated_i','rst_n'): continue
            lines.append(f"        {name} = {width}'h{row[name]:x};")
        lines.append('      end')
    lines.append('    endcase')
    lines.append('  end endtask')
    lines.append('  integer cycle;')
    lines.append('  initial begin')
    lines.append('    $dumpfile("toggle.vcd");')
    lines.append('    $dumpvars(0, tb.gold);')
    lines.append('    $dumpvars(0, tb.gate);')
    lines.append('    repeat (4) @(posedge clk);')
    lines.append('    rst_n = 1\'b1;')
    lines.append('    repeat (4) @(posedge clk);')
    lines.append('    @(negedge clk);')
    lines.append(f'    for (cycle = 0; cycle < {CYCLES}; cycle = cycle + 1) begin')
    lines.append('      apply_cycle(cycle);')
    lines.append('      @(posedge clk); #1;')
    lines.append('      if (gold_vec !== gate_vec) begin')
    lines.append('        $display("MISMATCH cycle=%0d gold=%h gate=%h", cycle, gold_vec, gate_vec);')
    lines.append('        $fatal(1);')
    lines.append('      end')
    lines.append('      @(negedge clk);')
    lines.append('    end')
    lines.append('    $display("cv32 activity replay completed cycles=%0d", cycle);')
    lines.append('    $finish;')
    lines.append('  end')
    lines.append('endmodule')
    return '\n'.join(lines)+'\n'

def normalize(value, width):
    value=value.lower()
    if any(ch not in '01' for ch in value): return None
    return value.zfill(width)[-width:]

def count_vcd(path: Path):
    scopes=[]; in_defs=True
    id_maps={}; prev={}
    path_owners={}; widths={}
    counts={'gold':0,'gate':0}; exercise={}
    alias_ids=0; common_paths=0; owner_only={'gold':0,'gate':0}
    with path.open() as f:
        for raw in f:
            line=raw.strip()
            if not line: continue
            if in_defs:
                if line.startswith('$scope'):
                    parts=line.split();
                    if len(parts)>=3: scopes.append(parts[2])
                elif line.startswith('$upscope'):
                    if scopes: scopes.pop()
                elif line.startswith('$var'):
                    parts=line.split()
                    if len(parts)>=5:
                        owner = scopes[1] if len(scopes) >= 2 and scopes[0] == 'tb' and scopes[1] in ('gold', 'gate') else None
                        if owner:
                            ident=parts[3]; name=parts[4]
                            canon='.'.join(scopes[2:]+[name])
                            id_maps.setdefault(ident, []).append((owner, canon, int(parts[2])))
                            path_owners.setdefault(canon, set()).add(owner)
                            widths[(owner, canon)] = int(parts[2])
                elif line.startswith('$enddefinitions'):
                    in_defs=False
                    alias_ids=sum(1 for maps in id_maps.values() if len(maps) > 1)
                    for canon, owners in path_owners.items():
                        if owners == {'gold'}:
                            owner_only['gold'] += 1
                        elif owners == {'gate'}:
                            owner_only['gate'] += 1
                        elif owners == {'gold', 'gate'} and widths.get(('gold', canon)) == widths.get(('gate', canon)):
                            common_paths += 1
                continue
            if line[0] in '01xz': ident=line[1:]; rawval=line[0]
            elif line[0] in 'bBrR':
                parts=line.split()
                if len(parts)!=2: continue
                rawval=parts[0][1:]; ident=parts[1]
            else: continue
            maps=id_maps.get(ident)
            if not maps: continue
            value=normalize(rawval, maps[0][2])
            if value is None:
                prev.pop(ident,None); continue
            old=prev.get(ident)
            if old is not None:
                flips=sum(a!=b for a,b in zip(old,value))
                for owner, canon, width in maps:
                    counts[owner]+=flips
                    if owner=='gold':
                        for key in ('instr_rdata_i','regfile_waddr_wb_i','regfile_alu_waddr_fw_i',
                                    'regfile_wdata_wb_i','regfile_alu_wdata_fw_i',
                                    'regfile_addr_ra_id','regfile_addr_rb_id','regfile_addr_rc_id',
                                    'regfile_data_ra_id','regfile_data_rb_id','regfile_data_rc_id',
                                    'raddr_a_i','raddr_b_i','raddr_c_i','rdata_a_o','rdata_b_o','rdata_c_o'):
                            if canon.endswith('.'+key) or canon.endswith('.'+key+'[31:0]') or canon == key:
                                exercise[key]=exercise.get(key,0)+flips
            prev[ident]=value
    return counts, exercise, {'vcd_alias_ids': alias_ids, 'common_gold_gate_paths': common_paths, 'owner_only_paths': owner_only}

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    work=OUT/'work'
    if work.exists(): shutil.rmtree(work)
    work.mkdir()
    gm=modules(GOLD.read_text()); tm=modules(GATE.read_text())
    names=list(gm.keys())
    if TOP not in gm or TOP not in tm: raise SystemExit('top missing')
    (work/'gold_design.v').write_text(prefix_design(GOLD.read_text(), 'gold_', names) + '\n' + (PACKAGE / 'sim_clock_gate.sv').read_text() + '\n')
    (work/'gate_design.v').write_text(prefix_design(GATE.read_text(), 'gate_', names))
    ports=parse_ports(gm[TOP])
    inputs=[p for p in ports if p[0]=='input']
    outputs=[p for p in ports if p[0]=='output']
    tr=trace([(n,w) for _,n,w in inputs])
    (OUT/'toggle_trace.json').write_text(json.dumps(tr, indent=2)+'\n')
    (work/'tb.v').write_text(make_tb(inputs, outputs, tr))
    cp=subprocess.run(['iverilog','-g2012','-o','simv','gold_design.v','gate_design.v','tb.v'], cwd=work, text=True, capture_output=True)
    if cp.returncode:
        (OUT/'toggle_sim.log').write_text(cp.stdout+cp.stderr)
        raise SystemExit(cp.stdout+cp.stderr)
    sp=subprocess.run(['vvp','simv'], cwd=work, text=True, capture_output=True)
    (OUT/'toggle_sim.log').write_text(cp.stdout+cp.stderr+sp.stdout+sp.stderr)
    if sp.returncode:
        raise SystemExit(sp.stdout+sp.stderr)
    shutil.copy2(work/'toggle.vcd', OUT/'toggle.vcd')
    counts, exercise, count_meta=count_vcd(OUT/'toggle.vcd')
    delta=0.0 if counts['gold']==0 else (counts['gate']-counts['gold'])/counts['gold']*100
    receipt={
        'power_status':'measured',
        'power_evidence_type':'toggle_convention',
        'power_method':'cv32_idstage_ex_readmask_context_iverilog_vcd_hierarchy_toggle_v1',
        'top':TOP,
        'sim_cycles':CYCLES,
        'stimulus':f'cv32.id_ex_readmask_context.regfile_read_write_mix+0x{SEED:x}',
        'gold_sha256':sha(GOLD),
        'gate_sha256':sha(GATE),
        'trace_sha256':sha(OUT/'toggle_trace.json'),
        'vcd_sha256':sha(OUT/'toggle.vcd'),
        'normalized_vcd_sha256':sha_vcd_norm(OUT/'toggle.vcd'),
        'sim_log_sha256':sha(OUT/'toggle_sim.log'),
        'gold_toggles':counts['gold'],
        'gate_toggles':counts['gate'],
        'toggle_delta_pct':round(delta,6),
        'toggle_status':'neutral_or_better' if counts['gate'] <= counts['gold'] else 'regression',
        'toggle_counting':'alias_safe_all_hierarchy_owner_counts',
        'toggle_counting_meta':count_meta,
        'required_exercise_measured':exercise,
        'boundary_equality_every_cycle':True,
        'no_x_or_z_on_primary_inputs':'construction_guaranteed_binary_assignments',
        'trace':'toggle_trace.json',
        'vcd':'toggle.vcd',
    }
    if exercise.get('regfile_data_ra_id',0) <= 0 or exercise.get('regfile_addr_ra_id',0) <= 0:
        receipt['power_status']='invalid_under_exercised'
        receipt['toggle_status']='invalid_under_exercised'
    (OUT/'toggle_convention_receipt.json').write_text(json.dumps(receipt, indent=2, sort_keys=True)+'\n')
    print(json.dumps(receipt, indent=2, sort_keys=True))
    if receipt['toggle_status'] != 'neutral_or_better':
        raise SystemExit(f"toggle status failed: {receipt['toggle_status']}")
    if counts['gold'] != 705913 or counts['gate'] != 705913:
        raise SystemExit(f"unexpected toggle counts: gold={counts['gold']} gate={counts['gate']}")

if __name__ == '__main__': main()
