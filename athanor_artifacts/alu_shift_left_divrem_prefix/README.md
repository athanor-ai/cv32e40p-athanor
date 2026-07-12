# CV32E40P ALU shift-left DIV/REM prefix packet

This package records a replay-grade evidence packet for `cv32e40p_alu / shift_left_divrem_prefix`.

Reader terms:

- ALU parent context: a bounded wrapper around the real CV32E40P ALU and the parent wires that consume its outputs. This is not a whole-core run.
- Selected-flow area/timing: the Yosys + Sky130 + OpenSTA measurement used for the local parent wrapper.
- Source-local equivalence: a proof that the rewritten Boolean predicate is identical to the old predicate for every 7-bit ALU operator value.
- Negative control: an intentionally wrong prefix that must fail. Here `01101` incorrectly drops a real REMU opcode, so the SAT check must find `diff_o=1`.
- Activity/toggle: a VCD toggle-count proxy on the same parent context. It is not a full power signoff.

Boundary: this is not an accepted CV32 optimization, not a full parent-equivalence proof, not a whole-core claim, and not a customer impact claim. It is a default ALU parent-context package that still needs independent replay.

Key results:

- Source delta is exactly one predicate replacement in `shift_left`.
- Predicate SAT proves the correct `operator_i[6:2] == 5'b01100` replacement over the full 7-bit operator space.
- Wrong-prefix `01101` negative control bites with `operator_i=0110010`, old predicate true, new predicate false, `diff_o=1`.
- Parent selected-flow area moves `29548.339200 -> 29433.228800` (`-0.389566%`).
- All five parent timing groups improve.
- Activity/toggle is flat on common paths: `1482734 -> 1482734`.

Replay commands are listed in `COMMANDS.md`.
