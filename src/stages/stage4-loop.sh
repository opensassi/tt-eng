#!/usr/bin/env bash
set -euo pipefail

# stage4-loop.sh
# Automated iteration loop: chains stages 1-3 autonomously.
# The agent drives the loop logic; this script provides
# the iteration scaffolding and result aggregation.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ITER="1"
VARIANT="baseline"
TASK="test"
RESULTS_DIR="$PROJECT_ROOT/results/stage4"
CONFIG_DIR="$PROJECT_ROOT/config"
EXPERIMENTS_DIR="$PROJECT_ROOT/results/experiments"

while [ $# -gt 0 ]; do
  case "$1" in
    --iter) ITER="$2"; shift 2;;
    --variant) VARIANT="$2"; shift 2;;
    --task) TASK="$2"; shift 2;;
    --results) RESULTS_DIR="$2"; shift 2;;
    --config) CONFIG_DIR="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

STAGE_RESULT="$RESULTS_DIR/stage-result.json"
echo "[stage4] Task: $TASK, Iter: $ITER, Variant: $VARIANT"

case "$TASK" in
  generate)
    echo "[stage4] Agent orchestrates the iteration loop."
    echo "[stage4] Tasks: generate kernel -> test -> if pass: bench -> archive -> repeat"
    mkdir -p "$PROJECT_ROOT/src/generated/stage4"
    jq '.status = "pass"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  test)
    echo "[stage4] Running iteration $ITER..."
    RUNNER="$SCRIPT_DIR/run-stage.sh"

    # Phase 1: Stage 1 (Copy Kernel)
    echo "[stage4] --- Phase 1: Copy Kernel ---"
    bash "$RUNNER" stage1 --iter "$ITER" --variant "$VARIANT" --task test
    RESULT1="$PROJECT_ROOT/results/stage1/stage-result.json"
    STATUS1=$(jq -r '.status' "$RESULT1")
    if [ "$STATUS1" != "pass" ]; then
      jq '.status = "fail" | .metrics.failed_phase = "stage1"' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi

    # Phase 2: Stage 2 (Elementwise Addition)
    echo "[stage4] --- Phase 2: Elementwise Addition ---"
    bash "$RUNNER" stage2 --iter "$ITER" --variant "$VARIANT" --task test
    RESULT2="$PROJECT_ROOT/results/stage2/stage-result.json"
    STATUS2=$(jq -r '.status' "$RESULT2")
    if [ "$STATUS2" != "pass" ]; then
      jq '.status = "fail" | .metrics.failed_phase = "stage2"' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi

    # Phase 3: Benchmark
    echo "[stage4] --- Phase 3: Benchmark ---"
    bash "$RUNNER" stage2 --iter "$ITER" --variant "$VARIANT" --task bench
    RESULT2B="$PROJECT_ROOT/results/stage2/stage-result.json"
    METRICS_FILE="$PROJECT_ROOT/results/stage2/benchmark/metrics.json"

    # Phase 4: Archive experiment
    EXP_DIR="$EXPERIMENTS_DIR/$(printf '%03d' "$ITER")-loop-iter-$ITER"
    mkdir -p "$EXP_DIR"
    if [ -f "$METRICS_FILE" ]; then
      cp "$METRICS_FILE" "$EXP_DIR/metrics.json"
    fi
    cp "$RESULT1" "$EXP_DIR/stage1-result.json"
    cp "$RESULT2" "$EXP_DIR/stage2-result.json"

    # Update experiments index
    INDEX="$EXPERIMENTS_DIR/experiments-index.json"
    if [ ! -f "$INDEX" ]; then
      echo '{"experiments":[]}' > "$INDEX"
    fi
    jq --arg id "$(printf '%03d' "$ITER")" \
       --arg label "loop-iter-$ITER" \
       --arg parent "$([ $ITER -gt 1 ] && echo "$(printf '%03d' $((ITER - 1)))-loop-iter-$((ITER - 1))" || echo 'null')" \
       '.experiments += [{"id": $id, "label": $label, "parent": $parent, "status": "completed"}]' \
       "$INDEX" > tmp.$$ && mv tmp.$$ "$INDEX"

    jq --argjson iter "$ITER" \
       '.status = "pass" | .metrics.iterations_completed = $iter' \
       "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  bench)
    echo "[stage4] No standalone bench - bench is part of the loop"
    jq '.status = "skipped"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;
esac

exit 0
