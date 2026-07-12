# Replay commands

Run these commands from `athanor_artifacts/compressed_decoder_l244_addi16sp_lui_zero_reduce` in a fresh checkout.

```bash
sha256sum -c SHA256SUMS
python3 replay_source_delta.py
python3 replay_predicate_equiv.py
python3 replay_full_decoder_equiv.py
python3 replay_selected_summary.py
OUT_DIR=/tmp/cv32-compressed-l244-activity-replay python3 activity/replay_toggle.py
```

The default Yosys path is `yosys`. Override it with `YOSYS=/path/to/yosys` if needed.

The activity replay uses `iverilog` and `vvp` by default. Override with `IVERILOG=/path/to/iverilog VVP=/path/to/vvp` if needed.
