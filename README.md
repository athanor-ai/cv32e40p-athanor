# Athanor CV32E40P Evidence Surface

CV32E40P is a real 32-bit in-order RISC-V core from OpenHW Group. This fork is
Athanor's public evidence surface for CV32E40P exploration. It currently carries
setup and scouting work, not a promoted optimization claim.

## Status

| Field | Current read |
| --- | --- |
| Core | OpenHW Group CORE-V CV32E40P |
| Evidence level | Exploration only; no promoted Athanor optimization row |
| Current public claim | No area/timing/power win is claimed for CV32E40P in this fork today |
| Claim boundary | A row promotes only after exact RTL provenance, selected-flow metrics, proof/equivalence, negative controls, and replay all close. |

## Promoted Evidence

No CV32E40P optimization has been promoted yet. This is deliberate: the public
README should not imply a win until the same bar used for Ibex and OpenC910 has
closed on a named package.

## Evidence Ledger

Current work is exploratory. Candidate or baseline evidence may appear in
artifact folders as scouting material, but it is not a customer-facing
optimization result until promoted into the table above.

When a CV32E40P result is ready, it will use the same fields as
the other public core repos:

| Target | Scope | Metric result | Correctness / activity receipt | Package |
| --- | --- | --- | --- | --- |
| _none yet_ | _not promoted_ | _not promoted_ | _not promoted_ | _not promoted_ |

## Evidence Bar

A promoted row requires:

1. Exact RTL provenance and package hashes.
2. Area, timing, and power-style measurements bound to the same candidate.
3. A scoped equivalence or property proof on the exact subject.
4. A biting proof negative-control.
5. A metric red-control that can fail the measurement gate.
6. Non-author replay or adversarial QA.

Anything missing one of these is a scout, hard negative, helper-only package, or
proof artifact, not a promoted result.

## Replay

Replay instructions will live beside any promoted package. Until then, use this
repo as the upstream RTL surface plus Athanor exploration workspace, not as a
claim surface.

## Upstream

The original OpenHW CV32E40P documentation and source tree are preserved. See
[`docs/`](docs/), [`CONTRIBUTING.md`](CONTRIBUTING.md), and [`LICENSE`](LICENSE)
for upstream terms.
