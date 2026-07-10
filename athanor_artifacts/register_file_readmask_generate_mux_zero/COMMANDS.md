# Replay Commands

Run these commands from this package directory.

```bash
sha256sum -c SHA256SUMS
python3 replay_selected_summary.py
./replay_parent_equiv.sh
./replay_rf_grid.sh
python3 activity/replay_toggle.py
python3 activity/replay_toggle_aa.py
python3 -m json.tool cv32e40p_register_file_ff_readmask_generate_mux_zero_manifest.json >/dev/null
```

Optional tool overrides:

```bash
export YOSYS=/path/to/yosys
export OUT_DIR=/tmp/cv32-readmask-generate-mux-zero-replay
```

The selected-flow summary replays the packaged split-parent reports. The
parent-equivalence and RF-grid commands recompute the proof receipts from
checked-in package files. The activity commands recompute alias-safe VCD toggle
counts using the upstream simulation clock-gate model checked into this package.
