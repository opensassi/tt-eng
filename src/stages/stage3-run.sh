#!/usr/bin/env bash
set -euo pipefail

# stage3-run.sh
# Performance Optimization stage: takes profiling data from stage2,
# agent proposes optimization, script benchmarks and compares.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ITER="1"
VARIANT="baseline"
TASK="test"
RESULTS_DIR="$PROJECT_ROOT/results/stage3"
CONFIG_DIR="$PROJECT_ROOT/config"
BASELINE_DIR="$PROJECT_ROOT/results/stage2/benchmark"

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
COMPILE_LOG="$RESULTS_DIR/compile-log.txt"
GENERATED_DIR="$PROJECT_ROOT/src/generated/stage3"
FULL_RESULTS="$RESULTS_DIR/test-suite/full-results/full-results.json"
FAILED_DIR="$RESULTS_DIR/test-suite/failed-tests"
BENCH_DIR="$RESULTS_DIR/benchmark"

echo "[stage3] Task: $TASK, Iter: $ITER, Variant: $VARIANT"

case "$TASK" in
  generate)
    echo "[stage3] Agent writes optimized kernel to $GENERATED_DIR/"
    mkdir -p "$GENERATED_DIR"

    # Load baseline metrics for agent reference
    if [ -f "$BASELINE_DIR/metrics.json" ]; then
      echo "[stage3] Baseline metrics available at $BASELINE_DIR/metrics.json"
      cat "$BASELINE_DIR/metrics.json"
    fi

    jq '.status = "pass"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  test)
    # Same compile + test pattern as stage2
    KERNEL_SRC="$GENERATED_DIR/kernel.cpp"
    if [ ! -f "$KERNEL_SRC" ]; then
      echo "[stage3] ERROR: No generated kernel at $KERNEL_SRC"
      jq '.status = "error" | .metrics.compile_error = "kernel source not found"' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi

    HW_CONFIG="$CONFIG_DIR/hardware.json"
    TT_METAL_HOME_VAL=$(jq -r '.env.TT_METAL_HOME' "$HW_CONFIG")
    TT_METAL_HOME_VAL="${TT_METAL_HOME_VAL/\$\{PROJECT_ROOT\}/$PROJECT_ROOT}"
    TTSIM_VAL=$(jq -r '.env.TT_METAL_SIMULATOR' "$HW_CONFIG")
    TTSIM_VAL="${TTSIM_VAL/\$\{PROJECT_ROOT\}/$PROJECT_ROOT}"

    export TT_METAL_HOME="$TT_METAL_HOME_VAL"
    export TT_METAL_SIMULATOR="$TTSIM_VAL"
    export TT_METAL_SLOW_DISPATCH_MODE=1

    BUILD_CMD="g++ -std=c++20 -O2 -g -fno-omit-frame-pointer \
      -I$TT_METAL_HOME -I$TT_METAL_HOME/tt_metal \
      -o $RESULTS_DIR/kernel_test $KERNEL_SRC \
      -L$TT_METAL_HOME/build/lib -ltt_metal \
      -L$(dirname "$TTSIM_VAL") -lttsim_bh -lpthread -ldl"

    echo "$BUILD_CMD" > "$COMPILE_LOG"
    if ! eval "$BUILD_CMD" >> "$COMPILE_LOG" 2>&1; then
      jq --arg log "$COMPILE_LOG" \
        '.status = "fail" | .artifacts.compile_log = $log | .metrics.compile_error = 1' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi

    TEST_OUTPUT="$RESULTS_DIR/test-suite/test-output.log"
    set +e
    "$RESULTS_DIR/kernel_test" 2>&1 | tee "$TEST_OUTPUT"
    TEST_EXIT=$?
    set -e

    cat > "$FULL_RESULTS" <<JSONEOF
{
  "tests": [{"name": "optimized_kernel", "status": "$([ $TEST_EXIT -eq 0 ] && echo "pass" || echo "fail")"}],
  "total": 1,
  "passed": $([ $TEST_EXIT -eq 0 ] && echo 1 || echo 0),
  "failed": $([ $TEST_EXIT -eq 0 ] && echo 0 || echo 1),
  "exit_code": $TEST_EXIT
}
JSONEOF

    STATUS="pass"; [ $TEST_EXIT -ne 0 ] && STATUS="fail"
    jq --arg log "$COMPILE_LOG" --arg status "$STATUS" \
       '.status = $status | .artifacts.compile_log = $log |
        .metrics.compile_error = 0 | .metrics.tests_total = 1 |
        .metrics.tests_passed = (if $status == "pass" then 1 else 0 end) |
        .metrics.tests_failed = (if $status == "pass" then 0 else 1 end)' \
       "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  bench)
    echo "[stage3] Benchmarking candidate..."
    PERF_OUT="$BENCH_DIR/perf.stat"

    set +e
    perf stat -e cycles,instructions,cache-misses,branch-misses \
      -o "$PERF_OUT" "$RESULTS_DIR/kernel_test" 2>&1
    PERF_EXIT=$?
    set -e

    CYCLES=$(grep -oP '^\s+[\d,]+(?=\s+cycles)' "$PERF_OUT" 2>/dev/null | tr -d ',' || echo "0")
    INSTRUCTIONS=$(grep -oP '^\s+[\d,]+(?=\s+instructions)' "$PERF_OUT" 2>/dev/null | tr -d ',' || echo "0")

    METRICS="$BENCH_DIR/metrics.json"
    cat > "$METRICS" <<JSONEOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "variant": "$VARIANT",
  "profile": {
    "cycles": ${CYCLES:-0},
    "instructions": ${INSTRUCTIONS:-0},
    "ipc": $(echo "scale=2; ${INSTRUCTIONS:-0} / ${CYCLES:-1}" | bc 2>/dev/null || echo "0"),
    "cache_misses": 0
  }
}
JSONEOF

    # Compare with baseline
    if [ -f "$BASELINE_DIR/metrics.json" ]; then
      BASELINE_IPC=$(jq -r '.profile.ipc // 0' "$BASELINE_DIR/metrics.json")
      CANDIDATE_IPC=$(jq -r '.profile.ipc // 0' "$METRICS")
      IPC_DELTA=$(echo "scale=2; if ($CANDIDATE_IPC > 0 && $BASELINE_IPC > 0) ($CANDIDATE_IPC - $BASELINE_IPC) / $BASELINE_IPC * 100 else 0" | bc 2>/dev/null || echo "0")

      COMPARISON="$BENCH_DIR/comparison.json"
      cat > "$COMPARISON" <<JSONEOF
{
  "baseline": "$BASELINE_DIR",
  "candidate": "$BENCH_DIR",
  "deltas": {
    "ipc": { "baseline": $BASELINE_IPC, "candidate": $CANDIDATE_IPC, "delta_pct": $IPC_DELTA }
  },
  "regression": $(echo "$IPC_DELTA < 0" | bc)
}
JSONEOF
      echo "[stage3] IPC delta: ${IPC_DELTA}%"
    fi

    jq '.status = "pass" | .artifacts.benchmark = "'$BENCH_DIR'"' \
      "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;
esac

exit 0
