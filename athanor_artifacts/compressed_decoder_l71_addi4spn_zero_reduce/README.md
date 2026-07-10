# CV32E40P compressed-decoder c.addi4spn zero-immediate packet

This package records a replay-grade evidence packet for one CV32E40P compressed-decoder rewrite:

`instr_i[12:5] == 8'b0` becomes `~|instr_i[12:5]` in the c.addi4spn zero-immediate legality check.

Reader terms:

- Compressed decoder: the instruction-fetch/decode helper that expands 16-bit RISC-V compressed instructions into 32-bit instructions and marks illegal compressed encodings.
- IF-stage parent context: the instruction-fetch stage containing the real compressed decoder, aligner, and prefetch path. This is not a whole-core run.
- Selected-flow area/timing: the Yosys + Sky130 + OpenSTA measurement used for the local parent wrapper.
- Source-local predicate equivalence: a proof that the rewritten Boolean predicate is identical to the old predicate for every relevant input value.
- Full decoder equivalence: a SAT proof over the complete `cv32e40p_compressed_decoder` outputs, not just the local predicate.
- Negative control: an intentionally wrong rewrite that must fail. This package includes missing-bit controls for bit 12 and bit 5 in both the local predicate and the full decoder miter.
- Activity/toggle: a VCD toggle-count proxy on the same IF-stage parent context. It is not a full power signoff.

Boundary: this is not an accepted CV32 optimization, not a whole-core claim, and not a customer-impact claim. It is a default IF-stage parent-context package that still needs independent replay.

Relationship to other packets: this packet is not additive with the c.addi16sp/c.lui compressed-decoder packet. Both measure the same IF-stage parent context; customer-table curation should keep them as separate candidate rows unless a combined packet is measured and replayed.

Key results:

- Source delta is exactly one predicate replacement.
- Source-local predicate SAT proves the replacement and two wrong-reduction controls bite.
- Full compressed-decoder output SAT proves equivalence for `FPU/ZFINX` tuples `00`, `10`, and `11`; two wrong-reduction full-decoder controls bite.
- IF-stage selected-flow area moves `18228.732800 -> 18207.462400` (`-0.116686%`).
- All five IF-stage timing groups improve.
- Compressed-decoder module area moves `1289.987200 -> 1278.726400` (`-0.872939%`).
- Activity/toggle is flat on common paths: `52962 -> 52962`.

Replay commands are listed in `COMMANDS.md`.
