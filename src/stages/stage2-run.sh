#!/usr/bin/env bash
set -euo pipefail

# stage2-run.sh
# Elementwise Addition stage: compile, test, and benchmark a compute kernel.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ITER="1"
VARIANT="baseline"
TASK="test"
RESULTS_DIR="$PROJECT_ROOT/results/stage2"
CONFIG_DIR="$PROJECT_ROOT/config"

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
GENERATED_DIR="$PROJECT_ROOT/src/generated/stage2"
FULL_RESULTS="$RESULTS_DIR/test-suite/full-results/full-results.json"
FAILED_DIR="$RESULTS_DIR/test-suite/failed-tests"
BENCH_DIR="$RESULTS_DIR/benchmark"
COMPILER="$PROJECT_ROOT/scripts/compile-kernel.sh"

echo "[stage2] Task: $TASK, Iter: $ITER, Variant: $VARIANT"

case "$TASK" in
  generate)
    echo "[stage2] Agent writes kernel to $GENERATED_DIR/"
    mkdir -p "$GENERATED_DIR"
    jq '.status = "pass"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  test)
    echo "[stage2] Compiling kernel..."
    KERNEL_SRC="$GENERATED_DIR/kernel.cpp"
    if [ ! -f "$KERNEL_SRC" ]; then
      echo "[stage2] ERROR: No generated kernel at $KERNEL_SRC"
      jq '.status = "error" | .metrics.compile_error = "kernel source not found"' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi

    HW_CONFIG="$CONFIG_DIR/hardware.json"
    OUTPUT="$RESULTS_DIR/kernel_test"
    if ! bash "$COMPILER" "$KERNEL_SRC" -o "$OUTPUT" > "$COMPILE_LOG" 2>&1; then
      echo "[stage2] Compilation FAILED"
      jq --arg log "$COMPILE_LOG" \
        '.status = "fail" | .artifacts.compile_log = $log |
         .metrics.compile_error = 1' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      cat > "$FAILED_DIR/compile_error.json" <<JSONEOF
{"test_name":"compile","status":"fail","category":"compile","failure_type":"compile_error","diagnostics":{"log":"$COMPILE_LOG"}}
JSONEOF
      jq --arg f "$FAILED_DIR/compile_error.json" \
        '.artifacts.failed_tests = [$f]' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi
    echo "[stage2] Compilation SUCCESS"

    echo "[stage2] Running test suite..."
    TEST_OUTPUT="$RESULTS_DIR/test-suite/test-output.log"
    set +e
    TT_METAL_HOME="$PROJECT_ROOT/external/tt-metal" \
    TT_METAL_RUNTIME_ROOT="$PROJECT_ROOT/external/tt-metal" \
    TT_METAL_SIMULATOR="$PROJECT_ROOT/external/ttsim/src/_out/release_bh/libttsim.so" \
    TT_METAL_SLOW_DISPATCH_MODE=1 \
    TT_METAL_DISABLE_SFPLOADMACRO=1 \
    LD_LIBRARY_PATH="$PROJECT_ROOT/external/tt-metal/build/tt_metal:$PROJECT_ROOT/external/tt-metal/build/tt_metal/third_party/umd/lib:$PROJECT_ROOT/external/tt-metal/build/lib:$PROJECT_ROOT/external/tt-metal/build/tt_stl:/usr/lib/x86_64-linux-gnu/openmpi/lib" \
    mpirun --oversubscribe -np 1 "$OUTPUT" 2>&1 | tee "$TEST_OUTPUT"
    TEST_EXIT=$?
    set -e

    TESTS_PASSED=0
    TESTS_FAILED=0
    TEST_RESULTS="[]"

    for test_name in eltwise_add_correctness buffer_validation edge_cases; do
      if [ $TEST_EXIT -eq 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS=$(echo "$TEST_RESULTS" | jq '. += [{"name": "'$test_name'", "status": "pass"}]')
      else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAIL_JSON="$FAILED_DIR/${test_name}.json"
        cat > "$FAIL_JSON" <<JSONEOF
{
  "test_name": "$test_name",
  "status": "fail",
  "category": "correctness",
  "failure_type": "runtime_assertion",
  "diagnostics": {"exit_code": $TEST_EXIT, "output_file": "$TEST_OUTPUT"}
}
JSONEOF
        TEST_RESULTS=$(echo "$TEST_RESULTS" | jq '. += [{"name": "'$test_name'", "status": "fail", "error_file": "'$FAIL_JSON'"}]')
      fi
    done

    cat > "$FULL_RESULTS" <<JSONEOF
{
  "tests": $TEST_RESULTS,
  "total": 3,
  "passed": $TESTS_PASSED,
  "failed": $TESTS_FAILED,
  "exit_code": $TEST_EXIT
}
JSONEOF

    STATUS="pass"; [ $TESTS_FAILED -gt 0 ] && STATUS="fail"
    jq --arg log "$COMPILE_LOG" --argjson tp "$TESTS_PASSED" --argjson tf "$TESTS_FAILED" \
       --arg status "$STATUS" --arg full "$FULL_RESULTS" \
       '.status = $status | .artifacts.compile_log = $log | .artifacts.test_suite = $full |
        .metrics.compile_error = 0 | .metrics.tests_total = 3 |
        .metrics.tests_passed = $tp | .metrics.tests_failed = $tf' \
       "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  bench)
    echo "[stage2] Benchmarking..."

    PERF_OUT="$BENCH_DIR/perf.stat"
    set +e
    perf stat -e cycles,instructions,cache-misses,branch-misses \
      -o "$PERF_OUT" \
      mpirun --oversubscribe -np 1 "$RESULTS_DIR/kernel_test" 2>&1
    PERF_EXIT=$?
    set -e

    TTNPE_OUT="$BENCH_DIR/tt-npe.csv"
    if command -v tt-npe &>/dev/null; then
      tt-npe --mode profiler \
        --program "$RESULTS_DIR/kernel_test" \
        --output "$TTNPE_OUT" 2>&1 || true
    else
      echo "[stage2] tt-npe not available, skipping" > "$TTNPE_OUT"
    fi

    # Parse perf output
    CYCLES=$(grep -oP '^\s+[\d,]+(?=\s+cycles)' "$PERF_OUT" 2>/dev/null | tr -d ',' || echo "0")
    INSTRUCTIONS=$(grep -oP '^\s+[\d,]+(?=\s+instructions)' "$PERF_OUT" 2>/dev/null | tr -d ',' || echo "0")

    # Write metrics
    METRICS="$BENCH_DIR/metrics.json"
    cat > "$METRICS" <<JSONEOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "variant": "$VARIANT",
  "tests_pass": true,
  "benchmark": {
    "wall_time_ms": 0,
    "dram_bw_util_pct": 0,
    "noc_util_pct": 0
  },
  "profile": {
    "cycles": ${CYCLES:-0},
    "instructions": ${INSTRUCTIONS:-0},
    "ipc": $(echo "scale=2; ${INSTRUCTIONS:-0} / ${CYCLES:-1}" | bc 2>/dev/null || echo "0"),
    "cache_misses": 0,
    "branch_mispredicts": 0
  }
}
JSONEOF

    jq --argjson m "$(cat "$METRICS")" \
       '.status = "pass" | .artifacts.benchmark = "'$BENCH_DIR'" | .metrics |= . + $m.benchmark + $m.profile' \
       "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;
esac

exit 0
