# cv32e40p_register_file_ff readmask_generate_mux_zero

This package is a CV32E40P default-configuration optimization candidate. It is
not a whole-core customer result yet, and it is not an accepted public
optimization until independent replay review closes.

## Reader Terms

- Split ID/EX parent context: a bounded wrapper containing the instruction
  decode stage, the execute-stage register boundary, and the real register-file
  consumer path used for this candidate. It is wider than the isolated register
  file and narrower than the whole core.
- Selected-flow: the bounded area and timing flow used to compare baseline and
  candidate under the same synthesis, mapping, and static-timing settings.
- RF or register file: the block that stores architectural register values.
- FPU: the optional floating-point unit. When enabled with `ZFINX=0`, the design
  has a separate floating-point register bank.
- ZFINX: a configuration where floating-point operations use the integer
  register file instead of a separate floating-point register bank.
- Yosys `$equiv` cells: comparison points inserted by Yosys when it builds an
  equivalence-checking circuit. A proven `$equiv` cell means the corresponding
  baseline and candidate signal matched under the proof assumptions.
- VCD toggle count: a count of signal transitions in a simulation waveform. It
  is activity evidence for this measured trace, not a full-chip power claim.
- A/A baseline control: a baseline-vs-baseline activity measurement used to
  check for activity-counting bias before comparing baseline against candidate.
- Boundary equality: a per-cycle simulation check that the candidate wrapper
  produces the same externally visible outputs as the baseline during the
  activity trace.

## Transform

Candidate: `readmask_generate_mux_zero`

The default CV32E40P configuration has no separate floating-point register bank.
In that mode, reads whose high address bit selects the floating-point bank return
zero. This candidate expresses that zero case through a generate-selected mux:
when `FPU=1` and `ZFINX=0`, the floating-point bank path is preserved; otherwise
high-bank reads return zero directly.

## Scope

The area, timing, and activity/toggle result is scoped to the measured default
split ID/EX parent context only: `FPU=0, ZFINX=0`.

Register-file equivalence is proven for the live `ADDR_WIDTH=6` grid:

- `FPU=0, ZFINX=0`
- `FPU=1, ZFINX=0`
- `FPU=1, ZFINX=1`

Those equivalence proofs do not claim area, timing, or activity for non-default
parent contexts. Measure those parent contexts separately before making a
parameter-generic claim.

## Evidence Summary

Split ID/EX selected-flow result:

| Metric | Baseline | Gate | Result |
| --- | ---: | ---: | --- |
| Area | `123569.763200` | `123434.633600` | `-0.109355%` |
| Overall slack | `-19.5738` | `-19.5634` | improved |
| Reg2reg slack | `-19.5738` | `-19.5634` | improved |
| Reg2out slack | `-18.7501` | `-18.7499` | improved |
| In2reg slack | `-4.9827` | `-4.8608` | improved |
| In2out slack | `-4.8178` | `-4.6949` | improved |

The isolated register-file module does not pass the local PPA bar: area moves
`31970.662400 -> 32005.696000`, and in2out/overall slack worsens
`0.7245 -> 0.4880`. This package is therefore a split-parent-context claim, not
an isolated-module win.

Formal:

- Normalized default `cv32e40p_id_stage` parent: `2820/2820` `$equiv` cells
  proven.
- Register-file grid: `1150/1150`, `2238/2238`, and `1150/1150` `$equiv` cells
  proven for the three tuples listed above.
- Negative control: a seeded bad high-bit mask leaves `32` unproven cells in the
  parent proof and in the register-file grid proof.

Activity/toggle:

- Boundary equality held every cycle in the split ID/EX trace.
- Required register-file address and data nets were exercised.
- Alias-safe VCD toggle count: `705913 -> 705913`, `0.0%`.

## Current Classification

`default_split_context_area_timing_equiv_activity_positive_needs_independent_replay`

The next gate is independent replay/package review. No `riscv-athanor` accepted
row or customer-impact claim should be added until that replay gate closes.

## Files

- `gold_source.sv`, `gate_source.sv`: source-level register-file snapshots.
- `gold_idstage_default.v`, `gate_idstage_default.v`: normalized default
  `cv32e40p_id_stage` parent bundles used for the load-bearing equivalence
  replay.
- `gold_split_context_default.v`, `gate_split_context_default.v`: split ID/EX
  parent bundles used for selected-flow and activity.
- `selected_flow/`: packaged split-parent area/timing reports.
- `equiv_idstage/`: parent proof inputs/logs and negative-control inputs/logs.
- `equiv_rf_grid/`: register-file grid proof inputs/logs.
- `activity/`: activity/toggle replay scripts, receipt, trace, and compressed
  VCD.
- `COMMANDS.md`: cold replay commands.
- `SHA256SUMS`: hashes for package files.
