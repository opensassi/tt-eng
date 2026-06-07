#!/usr/bin/env bash
set -euo pipefail

# run-stage.sh
# Single entry point for all stage operations.
# Usage: bash src/stages/run-stage.sh <stage-id> [options]
#
# Options:
#   --iter N         Iteration number (default: 1)
#   --variant LABEL  Experiment variant label (default: baseline)
#   --task TASK      Task: generate, test, bench (default: test)
#   --config PATH    Config directory (default: config/)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse arguments
STAGE_ID="${1:-}"
shift 2>/dev/null || true
ITER="1"
VARIANT="baseline"
TASK="test"
CONFIG_DIR="$PROJECT_ROOT/config"

while [ $# -gt 0 ]; do
  case "$1" in
    --iter) ITER="$2"; shift 2;;
    --variant) VARIANT="$2"; shift 2;;
    --task) TASK="$2"; shift 2;;
    --config) CONFIG_DIR="$2"; shift 2;;
    *) echo "ERROR: Unknown argument: $1"; exit 2;;
  esac
done

if [ -z "$STAGE_ID" ]; then
  echo "ERROR: stage-id is required"
  echo "Usage: run-stage.sh <stage-id> [--iter N] [--variant L] [--task T]"
  exit 2
fi

# Validate stage config
STAGE_CONFIG="$CONFIG_DIR/stages.json"
if [ ! -f "$STAGE_CONFIG" ]; then
  echo "ERROR: Stage config not found at $STAGE_CONFIG"
  exit 2
fi

# Resolve stage script
STAGE_SCRIPT="$SCRIPT_DIR/$STAGE_ID-run.sh"
if [ ! -f "$STAGE_SCRIPT" ]; then
  echo "ERROR: Stage script not found: $STAGE_SCRIPT"
  exit 2
fi

# Create results directory
RESULTS_DIR="$PROJECT_ROOT/results/$STAGE_ID"
mkdir -p "$RESULTS_DIR/test-suite/full-results"
mkdir -p "$RESULTS_DIR/test-suite/failed-tests"
mkdir -p "$RESULTS_DIR/benchmark"

# Initialize stage-result.json
STAGE_RESULT="$RESULTS_DIR/stage-result.json"
cat > "$STAGE_RESULT" <<JSONEOF
{
  "stage": "$STAGE_ID",
  "iteration": $ITER,
  "variant": "$VARIANT",
  "task": "$TASK",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "running",
  "artifacts": {
    "compile_log": "$RESULTS_DIR/compile-log.txt",
    "test_suite": "$RESULTS_DIR/test-suite/full-results/full-results.json",
    "failed_tests": [],
    "benchmark": null
  },
  "metrics": {}
}
JSONEOF

echo "[run-stage] Running $STAGE_ID (task: $TASK, iter: $ITER, variant: $VARIANT)"

# Execute stage script
if ! bash "$STAGE_SCRIPT" \
  --iter "$ITER" \
  --variant "$VARIANT" \
  --task "$TASK" \
  --results "$RESULTS_DIR" \
  --config "$CONFIG_DIR"; then
  echo "[run-stage] Stage script returned error"
fi

# Read final result
if [ -f "$STAGE_RESULT" ]; then
  STATUS="$(jq -r '.status' "$STAGE_RESULT")"
  echo "[run-stage] Stage complete: status=$STATUS"
  cat "$STAGE_RESULT"
else
  echo "[run-stage] WARNING: stage-result.json not found after execution"
fi
