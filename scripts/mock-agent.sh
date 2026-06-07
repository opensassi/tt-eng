#!/usr/bin/env bash
# mock-agent.sh
# Mock LLM agent for CI testing of the pipeline.
# Copies the reference kernel to the generated location,
# allowing pipeline logic (compile, test, bench) to be
# tested without an actual LLM API.
#
# Usage: bash scripts/mock-agent.sh <stage-id>
#   Copies test/reference-kernels/<stage-mapping>.cpp
#   to src/generated/<stage>/kernel.cpp

set -euo pipefail

STAGE_ID="${1:-}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "$STAGE_ID" ]; then
  echo "Usage: mock-agent.sh <stage-id>"
  echo "Stages: stage1, stage2"
  exit 2
fi

# Map stage to reference kernel
case "$STAGE_ID" in
  stage1)
    REFERENCE="$PROJECT_ROOT/test/reference-kernels/dram-loopback.cpp"
    ;;
  stage2)
    REFERENCE="$PROJECT_ROOT/test/reference-kernels/eltwise-add.cpp"
    ;;
  *)
    echo "ERROR: No reference kernel for stage '$STAGE_ID'"
    exit 1
    ;;
esac

TARGET_DIR="$PROJECT_ROOT/src/generated/$STAGE_ID"
mkdir -p "$TARGET_DIR"
cp "$REFERENCE" "$TARGET_DIR/kernel.cpp"

echo "[mock-agent] Copied reference kernel to $TARGET_DIR/kernel.cpp"
