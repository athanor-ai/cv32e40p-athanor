#!/usr/bin/env bash
# Seeded bite-proof for replay_changed_packets.sh — an un-fireable gate is
# no gate. Builds two fixture packets in a temp dir:
#   red:   a replay script that exits 1 mid-battery (the exact shape the
#          errexit-suppression bug greened: later commands still succeed)
#   green: the same battery with all commands passing
# The driver must FAIL the red fixture naming it, and PASS the green one.
# The workflow runs this BEFORE the real replay on every PR, so the gate
# proves it can still bite each time it is trusted.
set -euo pipefail

DRIVER="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/replay_changed_packets.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mk_pkg() {  # <dir> <replay-exit-code>
  local dir=$1 rc=$2
  mkdir -p "$dir"
  printf '#!/usr/bin/env python3\nimport sys\nsys.exit(%s)\n' "$rc" > "$dir/replay_source_delta.py"
  printf '{"schema": "fixture"}\n' > "$dir/fixture_manifest.json"
  ( cd "$dir" && sha256sum replay_source_delta.py fixture_manifest.json > SHA256SUMS )
}

mk_pkg "$tmp/athanor_artifacts/red_fixture" 1
mk_pkg "$tmp/athanor_artifacts/green_fixture" 0

echo "--- seeded RED fixture (replay script exits 1) must fail the driver:"
set +e
out=$(cd "$tmp" && bash "$DRIVER" --packets athanor_artifacts/red_fixture 2>&1)
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "::error::BITE-PROOF FAILED: a failing replay script did not fail the gate"
  echo "$out"
  exit 1
fi
case "$out" in
  *"replay failed for athanor_artifacts/red_fixture"*) ;;
  *) echo "::error::BITE-PROOF FAILED: failure did not name the packet"; echo "$out"; exit 1 ;;
esac

echo "--- seeded GREEN fixture must pass the driver:"
( cd "$tmp" && bash "$DRIVER" --packets athanor_artifacts/green_fixture )

echo "bite-proof OK: the replay gate demonstrably fails a failing packet and passes a passing one"
