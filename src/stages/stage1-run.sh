#!/usr/bin/env bash
set -euo pipefail

# stage1-run.sh
# Copy Kernel stage: compile generated DRAM loopback kernel,
# run full test suite, isolate failures, output structured results.
# Uses compile-kernel.sh and mpirun via stage_env.sh wrapper.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ITER="1"
VARIANT="baseline"
TASK="test"
RESULTS_DIR="$PROJECT_ROOT/results/stage1"
CONFIG_DIR="$PROJECT_ROOT/config"
KERNEL_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --iter) ITER="$2"; shift 2;;
    --variant) VARIANT="$2"; shift 2;;
    --task) TASK="$2"; shift 2;;
    --results) RESULTS_DIR="$2"; shift 2;;
    --config) CONFIG_DIR="$2"; shift 2;;
    --kernel-path) KERNEL_PATH="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

STAGE_RESULT="$RESULTS_DIR/stage-result.json"
COMPILE_LOG="$RESULTS_DIR/compile-log.txt"
GENERATED_DIR="$PROJECT_ROOT/src/generated/stage1"
FULL_RESULTS="$RESULTS_DIR/test-suite/full-results/full-results.json"
FAILED_DIR="$RESULTS_DIR/test-suite/failed-tests"
COMPILER="$PROJECT_ROOT/scripts/compile-kernel.sh"

if [ -n "${TT_GENERATED_KERNEL_PATH:-}" ]; then
  KERNEL_SRC="$TT_GENERATED_KERNEL_PATH"
elif [ -n "$KERNEL_PATH" ]; then
  KERNEL_SRC="$KERNEL_PATH"
else
  KERNEL_SRC="$GENERATED_DIR/kernel.cpp"
fi

echo "[stage1] Task: $TASK, Iter: $ITER, Variant: $VARIANT"
echo "[stage1] Kernel source: $KERNEL_SRC"

case "$TASK" in
  generate)
    echo "[stage1] Agent writes kernel to $GENERATED_DIR/"
    mkdir -p "$GENERATED_DIR"
    jq '.status = "pass" | .artifacts.kernel_source = "'$GENERATED_DIR'/kernel.cpp"' \
      "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  test)
    echo "[stage1] Compiling kernel..."
    if [ ! -f "$KERNEL_SRC" ]; then
      jq '.status = "error" | .metrics.compile_error = "kernel source not found at '"$KERNEL_SRC"'"' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi

    OUTPUT="$RESULTS_DIR/kernel_test"
    if ! bash "$COMPILER" "$KERNEL_SRC" -o "$OUTPUT" > "$COMPILE_LOG" 2>&1; then
      echo "[stage1] Compilation FAILED"
      jq --arg log "$COMPILE_LOG" \
        '.status = "fail" | .artifacts.compile_log = $log |
         .metrics.compile_error = 1 | .metrics.tests_total = 1 |
         .metrics.tests_passed = 0 | .metrics.tests_failed = 1' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"

      COMPILE_HEAD=$(head -20 "$COMPILE_LOG" 2>/dev/null | jq -Rs .)
      cat > "$FAILED_DIR/compile_error.json" <<JSONEOF
{
  "test_name": "compile",
  "status": "fail",
  "category": "compile",
  "failure_type": "compile_error",
  "diagnostics": {
    "log": "$COMPILE_LOG",
    "compiler_output_first_lines": $COMPILE_HEAD
  }
}
JSONEOF
      jq --arg f "$FAILED_DIR/compile_error.json" \
        '.artifacts.failed_tests = [$f]' \
        "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      exit 1
    fi
    echo "[stage1] Compilation SUCCESS"

    echo "[stage1] Running test suite..."
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

    if [ $TEST_EXIT -eq 0 ]; then
      TESTS_PASSED=1
      TEST_RESULTS=$(echo "$TEST_RESULTS" | jq '. += [{"name": "copy_kernel_correctness", "status": "pass"}]')
    else
      TESTS_FAILED=1
      FAIL_JSON="$FAILED_DIR/copy_kernel_correctness.json"
      cat > "$FAIL_JSON" <<JSONEOF
{
  "test_name": "copy_kernel_correctness",
  "status": "fail",
  "category": "correctness",
  "failure_type": "runtime_assertion",
  "diagnostics": {
    "exit_code": $TEST_EXIT,
    "output_file": "$TEST_OUTPUT"
  }
}
JSONEOF
      TEST_RESULTS=$(echo "$TEST_RESULTS" | jq '. += [{"name": "copy_kernel_correctness", "status": "fail", "error_file": "'$FAIL_JSON'"}]')
    fi

    cat > "$FULL_RESULTS" <<JSONEOF
{
  "tests": $TEST_RESULTS,
  "total": 1,
  "passed": $TESTS_PASSED,
  "failed": $TESTS_FAILED,
  "exit_code": $TEST_EXIT
}
JSONEOF

    STATUS="pass"; [ $TESTS_FAILED -gt 0 ] && STATUS="fail"
    jq --arg log "$COMPILE_LOG" --argjson tp "$TESTS_PASSED" --argjson tf "$TESTS_FAILED" \
       --arg status "$STATUS" --arg full "$FULL_RESULTS" \
       '.status = $status | .artifacts.compile_log = $log | .artifacts.test_suite = $full |
        .metrics.compile_error = 0 | .metrics.tests_total = 1 |
        .metrics.tests_passed = $tp | .metrics.tests_failed = $tf' \
       "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    echo "[stage1] Tests: $TESTS_PASSED passed, $TESTS_FAILED failed"
    ;;

  bench)
    echo "[stage1] No benchmark for stage 1"
    jq '.status = "skipped"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;
esac

exit 0
