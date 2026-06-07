#!/usr/bin/env bash
# generate-flamegraph.sh
# Generate a flamegraph SVG from a perf.data file.
#
# Usage: bash scripts/generate-flamegraph.sh <perf.data> [--output flame.svg]
#
# Requires: perf, FlameGraph/stackcollapse-perf.pl, FlameGraph/flamegraph.pl

set -euo pipefail

PERF_DATA="${1:-}"
OUTPUT="${2:-flame.svg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FG_DIR="$PROJECT_ROOT/scripts/FlameGraph"

if [ -z "$PERF_DATA" ] || [ ! -f "$PERF_DATA" ]; then
  echo "Usage: generate-flamegraph.sh <perf.data> [--output flame.svg]"
  exit 2
fi

if [ ! -d "$FG_DIR" ]; then
  echo "FlameGraph scripts not found at $FG_DIR"
  echo "Clone: git clone --depth 1 https://github.com/brendangregg/FlameGraph.git $FG_DIR"
  exit 1
fi

STACKCOLLAPSE="$FG_DIR/stackcollapse-perf.pl"
FLAMEGRAPH="$FG_DIR/flamegraph.pl"

if [ ! -f "$STACKCOLLAPSE" ]; then
  echo "ERROR: $STACKCOLLAPSE not found"
  exit 1
fi

if [ ! -f "$FLAMEGRAPH" ]; then
  echo "ERROR: $FLAMEGRAPH not found"
  exit 1
fi

WORKDIR="$(dirname "$PERF_DATA")"
FOLDED="$WORKDIR/folded.txt"

echo "[flamegraph] Generating folded stack from $PERF_DATA"
perf script -i "$PERF_DATA" 2>/dev/null | "$STACKCOLLAPSE" > "$FOLDED"

echo "[flamegraph] Generating flamegraph SVG -> $OUTPUT"
"$FLAMEGRAPH" "$FOLDED" > "$OUTPUT"

echo "[flamegraph] Done: $OUTPUT"
