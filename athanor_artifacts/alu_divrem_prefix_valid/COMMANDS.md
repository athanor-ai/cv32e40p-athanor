# Replay Commands

Run these commands from this package directory.

```bash
sha256sum -c SHA256SUMS
python3 replay_source_delta.py
python3 replay_predicate_equiv.py
python3 replay_selected_summary.py
python3 activity/replay_toggle.py
python3 -m json.tool cv32e40p_alu_divrem_prefix_valid_manifest.json >/dev/null
```

Optional tool overrides:

```bash
export YOSYS=/path/to/yosys
export OUT_DIR=/tmp/cv32-alu-divrem-replay
```

The formal evidence in this package is source-local. It proves the exact
`div_valid` predicate replacement and checks that the RTL delta is exactly that
one replacement. The old full ALU-parent equivalence attempt is included only
as a nondiscriminating harness-wall receipt: both the real candidate and the
wrong-prefix mutant leave the same number of unproven cells there.
