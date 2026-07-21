# Athanor CV32E40P Results

CV32E40P is a real 32-bit in-order RISC-V core from OpenHW Group. This fork
publishes scoped Athanor CV32E40P optimization results: exact RTL candidates,
selected-flow measurements, proof or equivalence evidence, negative controls,
and replay notes.

## Status

| Field | Status |
| --- | --- |
| Core | OpenHW Group CORE-V CV32E40P |
| Evidence level | Scoped parent-context packets; no whole-core CV32E40P claim |
| Current public claim | Area/timing/activity movement is claimed only at the measured packet scope |
| Claim boundary | No customer-ready claim, no full-core power claim, and no additive composition across overlapping packets. |

## Promoted Evidence

| Target | Scope | Metric result | Correctness / activity receipt | Package |
| --- | --- | --- | --- | --- |
| `cv32e40p_alu / addsub_divvalid_adderneg_prefixes` | ALU parent context | Area `29548.3392 -> 29208.0128`; all five timing groups improve | Source-local SAT equivalence; three negatives bite; activity flat | [`alu_addsub_divvalid_adderneg_prefixes`](athanor_artifacts/alu_addsub_divvalid_adderneg_prefixes/) |
| `cv32e40p_alu / shift_divvalid_adderneg_prefixes` | ALU parent context | Area `29548.3392 -> 29353.1520`; all five timing groups improve | Source-local SAT equivalence; three negatives bite; activity flat | [`alu_shift_divvalid_adderneg_prefixes`](athanor_artifacts/alu_shift_divvalid_adderneg_prefixes/) |
| `cv32e40p_alu / shift_left_divrem_prefix` | ALU parent context | Area `29548.3392 -> 29433.2288`; all five timing groups improve | Source-local SAT equivalence; wrong-prefix negative bites; activity flat | [`alu_shift_left_divrem_prefix`](athanor_artifacts/alu_shift_left_divrem_prefix/) |
| `cv32e40p_prefetch_controller / prefetch_hwlp_plus_next_cnt_arith` | IF-stage parent context | Area `18228.7328 -> 18187.4432`; all IF-stage timing groups improve | Source-local SAT equivalence; two negatives bite; activity flat; local prefetch-buffer timing caveat retained | [`prefetch_hwlp_plus_next_cnt_arith`](athanor_artifacts/prefetch_hwlp_plus_next_cnt_arith/) |
| `cv32e40p_register_file_ff / readmask_high_bank_zero` | Default ID-stage parent context | Area `111291.7376 -> 110963.9232`; measured timing groups flat or improved | Parent equivalence `2820/2820`; RF-grid equivalence closes; negative bites; activity flat | [`register_file_readmask_high_bank_zero`](athanor_artifacts/register_file_readmask_high_bank_zero/) |

## Proofs And Receipts

Proofs and replay receipts live inside the package linked from each row.

| Evidence | Where to look |
| --- | --- |
| Source-local SAT / predicate equivalence | Package-local `predicate_equiv/summary.json` and replay notes |
| Parent / grid equivalence | `register_file_readmask_high_bank_zero/equiv_idstage/logs/yosys_equiv.log` and `equiv_rf_grid/logs/real_*.log` |
| Negative controls | Package-local negative logs, negative summaries, and package manifests |
| Metrics and replay | Package README files, selected-flow summaries, `toggle_convention_receipt.json`, `SHA256SUMS`, and `python3 athanor/verify_public_receipts.py` |
| Lean / EBMC / CEGAR | Not claimed by these promoted rows unless a package explicitly carries that method's receipt |

## Evidence Ledger

Other artifact packages remain visible because they teach the search, but they
are not headline rows. Examples include compressed-decoder, prefetch, ALU, and
register-file candidates with local caveats or overlapping scopes. Do not add
metrics across overlapping packets unless a composed package measures that exact
composition.

## Evidence Bar

A promoted row requires:

1. Exact RTL provenance and package hashes.
2. Area, timing, and power-style measurements bound to the same candidate.
3. A scoped equivalence or property proof on the exact subject.
4. A biting proof negative-control.
5. A metric red-control that can fail the measurement gate.
6. Non-author replay or adversarial QA.

Anything missing one of these is a scout, hard negative, helper-only package, or
proof artifact, not a promoted result. Whole-core wording requires a whole-core
receipt.

## Replay

- Artifact packages: [`athanor_artifacts/`](athanor_artifacts/)
- Public receipt verifier: `python3 athanor/verify_public_receipts.py`
- Toolchain lock: [`tools/TOOLCHAIN.lock`](tools/TOOLCHAIN.lock)

Each package carries its own README and replay notes. This front page is the
concise status map.

## Upstream

The original OpenHW CV32E40P documentation and source tree are preserved. See
[`docs/`](docs/), [`CONTRIBUTING.md`](CONTRIBUTING.md), and [`LICENSE`](LICENSE)
for upstream terms.
