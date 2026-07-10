# cv32e40p_register_file_ff readmask_high_bank_zero

This package is a CV32E40P default-configuration optimization candidate. It is
not a whole-core customer result yet.

## Transform

Candidate: `readmask_high_bank_zero`

The default ID-stage context does not use a separate floating-point register
bank. In that configuration, register-file reads whose high address bit selects
the floating-point bank read zero. The candidate makes that zero behavior
explicit in the read mux while preserving the floating-point bank when
`FPU=1` and `ZFINX=0`.

## Scope

The area, timing, and activity/toggle result is scoped to the measured default
`cv32e40p_id_stage` parent context only.

Register-file equivalence is proven for the live `ADDR_WIDTH=6` grid:

- `FPU=0, ZFINX=0`
- `FPU=1, ZFINX=0`
- `FPU=1, ZFINX=1`

Those equivalence proofs do not claim area, timing, or activity for non-default
parent contexts. Measure those parent contexts separately before making a
parameter-generic claim.

## Evidence Summary

Default parent selected-flow result:

| Metric | Baseline | Gate | Result |
| --- | ---: | ---: | --- |
| Area | `111291.737600` | `110963.923200` | `-0.29455%` |
| Overall slack | `-10.2941` | `-10.2198` | improved |
| Reg2reg slack | `-4.3976` | `-4.3976` | flat |
| Reg2out slack | `-2.0943` | `-2.0943` | flat |
| In2reg slack | `-10.2941` | `-10.2198` | improved |
| In2out slack | `-4.0621` | `-3.7434` | improved |

Formal:

- Parent `cv32e40p_id_stage`: `2820/2820` `$equiv` cells proven.
- Register-file grid: `1150/1150`, `2238/2238`, and `1150/1150` `$equiv`
  cells proven for the three tuples listed above.
- Negative control: a seeded bad high-bit mask leaves `32` unproven
  `regfile_data_ra_id` bits in the parent proof.

Activity/toggle:

- Boundary equality held every cycle in the default ID-stage trace.
- Required register-file address and data nets were exercised.
- Alias-safe VCD toggle count: `530322 -> 530322`, `0.0%`.
- A/A baseline control is also flat: `530322 -> 530322`.

## Current Classification

`parent_context_area_timing_equiv_activity_positive_needs_replay_package`

The next gate is an independent replay/package review. No `riscv-athanor`
accepted row should be added until that replay gate closes.

## ATH-2853 Replay Handoff

`cv32e40p_register_file_ff_readmask_high_bank_zero_manifest.json` is the
machine-readable packet manifest for the replay gate. It records the default
parent-context scope, the register-file equivalence grid, the selected-flow
area/timing numbers, the activity/toggle receipts, and the biting negative
controls.

`relation_aware_miter/` contains the handoff shape Perry requested for the
ATH-2853 ingest leg:

- distinct gold, gate, and mutant parent-bundle source files;
- an adapter miter source over the same default parent context;
- `relation_aware_seq_miter_manifest.json`, which points back to the same
  load-bearing packet manifest.

The adapter miter elaborates, but its K=4 temporal-induction experiment is not
the positive proof receipt. The load-bearing proof in this package is the
checked-in Yosys `equiv_make` / `equiv_induct` replay in
`replay_parent_equiv.sh`, with the mutant bite in the same command path.

## Files

- `gold_source.sv`, `gate_source.sv`: source-level register-file snapshots.
- `gold_idstage_default.v`, `gate_idstage_default.v`: sv2v-normalized default
  parent bundles used for selected-flow, parent equivalence, and activity.
- `selected_flow/`: packaged default parent area/timing reports.
- `equiv_idstage/`: parent proof inputs/logs and negative-control inputs/logs.
- `equiv_rf_grid/`: register-file grid proof inputs/logs.
- `activity/`: activity/toggle replay script, A/A control, receipts, and
  compressed VCDs.
- `relation_aware_miter/`: ATH-2853 handoff files and adapter-miter logs.
- `COMMANDS.md`: cold replay commands.
- `SHA256SUMS`: hashes for package files.
