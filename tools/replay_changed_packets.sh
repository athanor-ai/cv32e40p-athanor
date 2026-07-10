#!/usr/bin/env bash
# Replay every changed artifact packet from a clean workspace.
#
# Usage:
#   replay_changed_packets.sh --base <ref>       # packets changed vs <ref>
#   replay_changed_packets.sh --packets <dir>... # explicit packet dirs (self-test)
#
# Runs as its own set -e script ON PURPOSE: an inline `( cmds ) || handler`
# subshell suppresses errexit on its left-hand side, so a failing replay
# command would fall through to the next line and the subshell would return
# the LAST command's status — a failing replay could green the gate as long
# as the manifest still parsed. Here every replay command's failure aborts
# the packet via explicit propagation, and packets are aggregated so one
# bad packet does not hide another.
set -euo pipefail

REPLAY_SCRIPTS=(
  replay_source_delta.py
  replay_predicate_equiv.py
  replay_full_decoder_equiv.py
  replay_parent_equiv.sh
  replay_rf_grid.sh
  replay_selected_summary.py
  activity/replay_toggle.py
)

replay_one() {
  local pkg=$1
  (
    cd "$pkg" || exit 1
    sha256sum -c SHA256SUMS || exit 1
    for script in "${REPLAY_SCRIPTS[@]}"; do
      if [ -f "$script" ]; then
        echo "--- $script"
        case "$script" in
          *.py) python3 "$script" || exit 1 ;;
          *.sh) bash "$script" || exit 1 ;;
          *) echo "unsupported replay script type: $script" >&2; exit 1 ;;
        esac
      fi
    done
    python3 -c "import json,glob; [json.load(open(f)) for f in glob.glob('*_manifest.json')]" || exit 1
  )
}

pkgs=()
case "${1:-}" in
  --base)
    base=${2:?--base needs a ref}
    mapfile -t pkgs < <(git diff --name-only "$base"...HEAD -- athanor_artifacts/ \
      | cut -d/ -f1-2 | sort -u)
    ;;
  --packets)
    shift
    pkgs=("$@")
    ;;
  *)
    echo "usage: $0 --base <ref> | --packets <dir>..." >&2
    exit 2
    ;;
esac

if [ "${#pkgs[@]}" -eq 0 ]; then
  echo "no packet dirs changed"
  exit 0
fi

fail=0
for pkg in "${pkgs[@]}"; do
  [ -d "$pkg" ] || continue   # deleted packet dirs have nothing to replay
  echo "=== replaying $pkg from a fresh clone"
  if ! replay_one "$pkg"; then
    echo "::error::replay failed for $pkg"
    fail=1
  fi
done
exit "$fail"
