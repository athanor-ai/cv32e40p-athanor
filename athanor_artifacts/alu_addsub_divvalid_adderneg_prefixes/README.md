# CV32E40P ALU add/sub, div-valid, and adder-negate prefix packet

This package records a replay-grade evidence packet for a three-predicate CV32E40P ALU rewrite: `shift_use_round`, `div_valid`, and `adder_op_b_negate`.

Reader terms:

- ALU parent context: a bounded wrapper around the real CV32E40P ALU and the parent wires that consume its outputs. This is not a whole-core run.
- Selected-flow area/timing: the Yosys + Sky130 + OpenSTA measurement used for the local parent wrapper.
- Source-local equivalence: a proof that the rewritten Boolean predicates are identical to the old predicates for every relevant input value.
- Negative control: an intentionally wrong rewrite that must fail. This package includes one biting negative for each predicate family.
- Activity/toggle: a VCD toggle-count proxy on the same parent context. It is not a full power signoff.

Boundary: this is not an accepted CV32 optimization, not a full parent-equivalence proof, not a whole-core claim, and not a customer impact claim. It is a default ALU parent-context package that still needs independent replay.

Relationship to earlier packets: this candidate includes the same `div_valid` rewrite packaged separately in `alu_divrem_prefix_valid` and adds two more ALU predicate rewrites. Treat the two packets as overlapping alternatives; do not add their area, timing, or activity numbers together. If both packets are shown in a public results table, this one should carry an explicit superset/dominance note relative to the div-valid-only packet.

Key results:

- Source delta is exactly three predicate replacements.
- Predicate SAT proves the combined replacement over `operator_i`, `enable_i`, and `is_subrot_i`; this is a combined three-predicate proof shape, not three separate accepted promotions.
- Three negative controls bite: add/sub wrong prefix, div/rem wrong prefix, and inverted sub-bit adder-negate.
- Parent selected-flow area moves `29548.339200 -> 29208.012800` (`-1.151762%`).
- All five parent timing groups improve.
- Activity/toggle is flat on common paths: `1482734 -> 1482734`.

Replay commands are listed in `COMMANDS.md`.
