# Athanor CV32E40P Artifact Packages

This directory contains replayable evidence packets for bounded RTL candidates
on the OpenHW CV32E40P RISC-V core.

Each package is scoped. Most packets are parent-context or local-module
evidence, not whole-core claims. The packets include input RTL snapshots,
candidate RTL snapshots, selected-toolchain area/timing measurements,
scoped equivalence evidence, negative controls, activity/toggle receipts where
available, and `SHA256SUMS` manifests.

## Packages

| Package | Status |
| --- | --- |
| [`alu_addsub_divvalid_adderneg_prefixes/`](alu_addsub_divvalid_adderneg_prefixes/) | ALU parent-context evidence: area -1.151762%, all five timing groups improve, source-local SAT equivalence for the rewritten predicates, three biting negative controls, toggle flat. |
| [`alu_shift_divvalid_adderneg_prefixes/`](alu_shift_divvalid_adderneg_prefixes/) | ALU parent-context evidence: area -0.660569%, all five timing groups improve, source-local SAT equivalence, three biting negative controls, toggle flat. |
| [`alu_shift_left_divrem_prefix/`](alu_shift_left_divrem_prefix/) | ALU parent-context evidence: area -0.389566%, all five timing groups improve, source-local SAT equivalence, wrong-prefix negative control, toggle flat. |
| [`alu_divrem_prefix_valid/`](alu_divrem_prefix_valid/) | ALU parent-context evidence: area -0.118564%, all five timing groups improve, source-local SAT equivalence, wrong-prefix negative control, toggle flat. |
| [`compressed_decoder_l244_addi16sp_lui_zero_reduce/`](compressed_decoder_l244_addi16sp_lui_zero_reduce/) | IF-stage parent-context evidence: area -0.185325%, all five timing groups improve, full compressed-decoder SAT equivalence, wrong-reduction controls, toggle flat. |
| [`compressed_decoder_l71_addi4spn_zero_reduce/`](compressed_decoder_l71_addi4spn_zero_reduce/) | IF-stage parent-context evidence: area -0.116686%, all five timing groups improve, full compressed-decoder SAT equivalence, wrong-reduction controls, toggle flat. |
| [`prefetch_hwlp_flush_demorgan/`](prefetch_hwlp_flush_demorgan/) | Prefetch-buffer parent-context evidence: area -0.226323%, all five local timing groups improve, source-local SAT equivalence, two negative controls, toggle flat. |
| [`prefetch_hwlp_plus_next_cnt_arith/`](prefetch_hwlp_plus_next_cnt_arith/) | IF-stage scoped evidence with caveat: IF-stage area -0.226508% and all IF-stage timing groups improve; local prefetch-buffer in2out regresses and is explicitly called out. |
| [`register_file_readmask_high_bank_zero/`](register_file_readmask_high_bank_zero/) | Default ID-stage parent-context evidence: area -0.29455%, timing flat or improved, Yosys parent equivalence closes `2820/2820` cells, RF-grid equivalence closes listed tuples, toggle flat. |
| [`register_file_readmask_generate_mux_zero/`](register_file_readmask_generate_mux_zero/) | Split ID/EX parent-context evidence: area -0.109355%, timing flat or improved, Yosys parent equivalence closes `2820/2820` cells, RF-grid equivalence closes listed tuples, toggle flat. |

## Replay

From the repository root:

```bash
python3 athanor/verify_public_receipts.py
```

From an individual package directory:

```bash
sha256sum -c SHA256SUMS
cat COMMANDS.md
```

The package-level commands replay the local evidence for that packet. The
top-level verifier checks public hash and manifest consistency without exposing
candidate-generation internals.
