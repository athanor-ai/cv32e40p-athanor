# Replay commands

Run these commands from `athanor_artifacts/compressed_decoder_l71_addi4spn_zero_reduce` in a fresh checkout.

```bash
sha256sum -c SHA256SUMS
python3 replay_source_delta.py
python3 replay_predicate_equiv.py
python3 replay_full_decoder_equiv.py
python3 replay_selected_summary.py
OUT_DIR=/tmp/cv32-compressed-l71-activity-replay python3 activity/replay_toggle.py
```

The default Yosys path is `/workdir/_tools/oss-cad-suite-20260630/bin/yosys`. Override it with `YOSYS=/path/to/yosys` if needed.

The activity replay uses `/workdir/_tools/oss-cad-suite-20260630/bin/iverilog` and `/workdir/_tools/oss-cad-suite-20260630/bin/vvp` by default. Override with `IVERILOG=/path/to/iverilog VVP=/path/to/vvp` if needed.
