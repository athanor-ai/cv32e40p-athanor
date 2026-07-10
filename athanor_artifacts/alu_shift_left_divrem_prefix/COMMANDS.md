# Replay Commands

Run from `athanor_artifacts/alu_shift_left_divrem_prefix`:

```bash
sha256sum -c SHA256SUMS
python3 replay_source_delta.py
python3 replay_predicate_equiv.py
python3 replay_selected_summary.py
python3 activity/replay_toggle.py
python3 -m json.tool cv32e40p_alu_shift_left_divrem_prefix_manifest.json >/dev/null
```

Optional environment:

- `YOSYS=/path/to/yosys` for `replay_predicate_equiv.py`
- `OUT_DIR=/tmp/somewhere` for `activity/replay_toggle.py`
