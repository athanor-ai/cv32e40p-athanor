# cv32e40p_alu divrem_prefix_valid

This package is a CV32E40P default-configuration optimization candidate. It is
not a whole-core customer result, and it is not an accepted public optimization
until independent replay review closes.

## Reader Terms

- ALU: the arithmetic logic unit. It computes integer arithmetic, bit
  operations, comparisons, and division/remainder control for this context.
- DIV/REM: division and remainder operations. In this package, the candidate
  rewrites the predicate that recognizes the four DIV/REM opcodes.
- Predicate: a boolean expression used to decide whether a signal is true.
- Source-local equivalence: a proof over the exact boolean expression that was
  rewritten. It is narrower than a full parent-module equivalence proof.
- Parent context: the bounded wrapper around the ALU used for area, timing, and
  activity measurement. It is wider than the one predicate and narrower than the
  whole processor.
- Selected-flow: the bounded area and timing flow used to compare baseline and
  candidate under the same synthesis, mapping, and static-timing settings.
- VCD toggle count: a count of signal transitions in a simulation waveform. It
  is activity evidence for this measured trace, not a full-chip power claim.
- Boundary equality: a per-cycle simulation check that the candidate parent
  context produces the same externally visible outputs as the baseline during
  the activity trace.

## Transform

Candidate: `divrem_prefix_valid`

The original ALU source recognizes DIV/REM with four explicit opcode equality
checks:

```systemverilog
assign div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                     (operator_i == ALU_REM) || (operator_i == ALU_REMU));
```

The candidate uses the shared opcode prefix for those four operations:

```systemverilog
assign div_valid = enable_i & (operator_i[6:2] == 5'b01100);
```

`replay_source_delta.py` checks that this is the only source change in
`cv32e40p_alu.sv`.

## Scope

Area, timing, and activity/toggle evidence is scoped to the measured default
ALU parent context only. This package does not claim a whole-core result and
does not claim a full ALU-parent formal equivalence proof.

The semantic evidence is source-local: `replay_predicate_equiv.py` proves the
old and new `div_valid` predicates are equivalent for the full 7-bit
`operator_i` space, and the seeded wrong-prefix control (`01101`) fails with a
counterexample.

The older full ALU-parent equivalence attempt is included only as a harness-wall
receipt. It is nondiscriminating because the real candidate and wrong-prefix
negative control both leave `1032` unproven `$equiv` cells. It is therefore not
used as promotion evidence.

## Evidence Summary

ALU parent selected-flow result:

| Metric | Baseline | Gate | Result |
| --- | ---: | ---: | --- |
| Area | `29548.339200` | `29513.305600` | `-0.118564%` |
| Overall slack | `-20.2186` | `-14.4180` | improved |
| Reg2reg slack | `-4.9985` | `-3.9626` | improved |
| Reg2out slack | `-2.4968` | `-1.8351` | improved |
| In2reg slack | `-16.2551` | `-11.4272` | improved |
| In2out slack | `-20.2186` | `-14.4180` | improved |

Source-local formal:

- Exact source-delta check: gate source is baseline source with exactly one
  `div_valid` predicate replacement.
- Output-level SAT check: `diff_o == 0` closes for the real prefix `01100`.
- Negative control: prefix `01101` fails with `operator_i=7'b0110101`,
  `old_div_valid=0`, `new_div_valid=1`, and `diff_o=1`.

Activity/toggle:

- Boundary equality held every cycle in the DIV/REM-heavy ALU parent trace.
- The divider control path was exercised, including `alu_i.div_valid`.
- Common-path VCD toggle count: `1482734 -> 1482734`, `0.0%`.

## Current Classification

`default_alu_parent_area_timing_activity_positive_source_local_equiv_needs_independent_replay`

The next gate is independent replay/package review. No `riscv-athanor` accepted
row or customer-impact claim should be added until that review closes.

## Files

- `gold_source.sv`, `gate_source.sv`: source-level ALU snapshots.
- `gold_alu_parent_context.v`, `gate_alu_parent_context.v`: parent-context
  bundles used for selected-flow and activity.
- `SOURCE_DIFF.patch`: unified source diff.
- `source_delta/`: reserved namespace for source-delta receipts.
- `predicate_equiv/`: output-level SAT miter inputs and logs.
- `selected_flow/`: packaged parent area/timing summaries and reports.
- `activity/`: activity/toggle replay script, receipt, trace, and compressed VCD.
- `parent_equiv_wall/`: nondiscriminating full-parent equiv attempt, included as
  a harness-wall receipt only.
- `COMMANDS.md`: cold replay commands.
- `SHA256SUMS`: hashes for package files.
