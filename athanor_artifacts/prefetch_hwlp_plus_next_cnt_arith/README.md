# CV32E40P prefetch HWLP plus next-count arithmetic packet

This package records a dual-scope replay-grade evidence packet for two `cv32e40p_prefetch_controller` rewrites:

- `next_cnt` case logic becomes `cnt_q + count_up - count_down`.
- `hwlp_flush_resp` uses the De Morgan form from the earlier HWLP packet.

Reader terms:

- IF-stage: the enclosing fetch/decode front-end parent wrapper used as this packet's claim scope.
- Prefetch-buffer: the immediate parent wrapper around the prefetch controller. This packet keeps its local timing caveat visible.
- Selected-flow area/timing: the Yosys + Sky130 + OpenSTA measurement used for the parent wrappers.
- Source-local equivalence: a proof that the rewritten expressions produce identical outputs for every relevant input value.
- Negative control: an intentionally wrong rewrite that must fail. This package includes one biting negative for each replacement family.
- Activity/toggle: a VCD toggle-count proxy on the prefetch-buffer boundary. It is not full power signoff.

Classification: `if_stage_scoped_win_with_named_prefetch_buffer_in2out_regression`.

Boundary: this is not an accepted CV32 optimization, not a whole-core claim, and not a customer-impact claim. The claim scope is the default IF-stage parent context. The immediate prefetch-buffer local in2out regression is a first-class caveat, not a footnote.

Key results:

- Source delta is exactly two replacements with no other movement.
- Combined SAT proves both replacement outputs; the De Morgan negative and next-count negative both bite.
- IF-stage selected-flow area moves `18228.732800 -> 18187.443200` (`-0.226508%`) and all five timing groups improve.
- Prefetch-buffer selected-flow area moves `7186.892800 -> 7130.588800` (`-0.783426%`), but local `in2out` regresses `2.6664 -> 2.6492` (`-0.0172`). Customers whose constraint set makes that local path critical should inspect this caveat before reuse.
- Activity/toggle is flat on common paths: `21739 -> 21739`.

Relationship to prior packet #6: this packet includes #6's HWLP De Morgan replacement and adds the `next_cnt` arithmetic rewrite. It is a non-additive successor/alternative, not an additive row. It dominates #6 on IF-stage metrics but carries the named local prefetch-buffer in2out regression.

Replay commands are listed in `COMMANDS.md`.
