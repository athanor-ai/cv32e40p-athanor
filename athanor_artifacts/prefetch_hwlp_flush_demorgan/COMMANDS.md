# Replay commands

Run these commands from `athanor_artifacts/prefetch_hwlp_flush_demorgan` in a fresh checkout.

```bash
sha256sum -c SHA256SUMS
python3 replay_source_delta.py
python3 replay_predicate_equiv.py
python3 replay_selected_summary.py
OUT_DIR=/tmp/cv32-prefetch-hwlp-flush-demorgan-activity-replay python3 activity/replay_toggle.py
```

The default Yosys path is `yosys`. Override it with `YOSYS=/path/to/yosys` if needed.

The activity replay uses `/opt/oss-cad-suite/bin/iverilog` and `/opt/oss-cad-suite/bin/vvp` by default. Override with `IVERILOG=/path/to/iverilog VVP=/path/to/vvp` if needed.
