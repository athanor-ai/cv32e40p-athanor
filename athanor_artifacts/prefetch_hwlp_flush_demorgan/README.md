# CV32E40P prefetch-buffer HWLP flush de Morgan packet

This package records a replay-grade evidence packet for one CV32E40P prefetch-controller rewrite:

`hwlp_jump_i && !(fifo_empty_i && !resp_valid_i)` becomes `hwlp_jump_i && (!fifo_empty_i || resp_valid_i)`.

Reader terms:

- Prefetch buffer: the instruction-fetch block that requests instruction memory data and queues returned instructions before decode.
- HWLP: hardware loop support. This packet exercises the prefetch logic that flushes outstanding requests when a hardware-loop jump is taken.
- Right-sized parent context: the smallest wrapper that contains the changed predicate and the real consuming logic. Here that is `cv32e40p_prefetch_buffer`.
- IF-stage: the wider instruction-fetch stage that contains the prefetch buffer and other unrelated logic. This packet records that the wider IF-stage wrapper was neutral, not a win.
- Selected-flow area/timing: the Yosys + Sky130 + OpenSTA measurement used for the local wrapper.
- Source-local equivalence: a proof that the rewritten Boolean predicate is identical to the old predicate for every value of its inputs.
- Negative control: an intentionally wrong rewrite that must fail. This package includes two biting negatives.
- Activity/toggle: a VCD toggle-count proxy on the same prefetch-buffer parent context. It is not a full power signoff.

Boundary: this is not an accepted CV32 optimization, not a full parent-equivalence proof, not a whole-core claim, not an IF-stage win, and not a customer-impact claim. It is a prefetch-buffer parent-context package that still needs independent replay.

Key results:

- Source delta is exactly one predicate replacement.
- Predicate SAT proves the replacement over `hwlp_jump_i`, `fifo_empty_i`, and `resp_valid_i`.
- Two negative controls bite: dropping the `hwlp_jump_i` guard and using the wrong de Morgan form.
- Prefetch-buffer selected-flow area moves `7186.892800 -> 7170.627200` (`-0.226323%`).
- All five prefetch-buffer timing groups improve.
- IF-stage wrapper is neutral: area and all timing buckets are unchanged.
- Activity/toggle is flat on common paths: `21739 -> 21739`.

Replay commands are listed in `COMMANDS.md`.
