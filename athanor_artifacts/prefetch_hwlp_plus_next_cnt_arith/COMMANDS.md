# Replay Commands

Run from `athanor_artifacts/prefetch_hwlp_plus_next_cnt_arith`:

```bash
sha256sum -c SHA256SUMS
python3 replay_source_delta.py
python3 replay_predicate_equiv.py
python3 replay_selected_summary.py
python3 activity/replay_toggle.py
python3 -m json.tool cv32e40p_prefetch_hwlp_plus_next_cnt_arith_manifest.json >/dev/null
```

Optional environment:

- `YOSYS=/path/to/yosys` for `replay_predicate_equiv.py`
- `IVERILOG=/path/to/iverilog VVP=/path/to/vvp` for `activity/replay_toggle.py`
- `OUT_DIR=/tmp/somewhere` for `activity/replay_toggle.py`
