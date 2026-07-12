# Replay Commands

Run these commands from this package directory.

```bash
sha256sum -c SHA256SUMS
python3 replay_selected_summary.py
./replay_parent_equiv.sh
./replay_rf_grid.sh
python3 activity/replay_toggle.py
python3 activity/replay_toggle_aa.py
python3 -m json.tool cv32e40p_register_file_ff_readmask_high_bank_zero_manifest.json >/dev/null
python3 -m json.tool relation_aware_miter/relation_aware_seq_miter_manifest.json >/dev/null
```

Optional tool overrides:

```bash
export YOSYS=/path/to/yosys
export OUT_DIR=/tmp/cv32-readmask-replay
```

The selected-flow summary replays the packaged reports. The equivalence and
activity commands recompute their receipts from checked-in package files.

The parent equivalence command uses Yosys `equiv_make` / `equiv_induct`; it does
not use an explicit `sat -seq K` command. The adapter-miter log in
`relation_aware_miter/logs/` is included as auxiliary adapter-miter evidence, but
it is not the promotion proof.
