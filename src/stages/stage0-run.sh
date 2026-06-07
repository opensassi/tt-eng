#!/usr/bin/env bash
set -euo pipefail

# stage0-bootstrap.sh
# Environment bootstrap: install tools, clone + build tt-metal + ttsim.
# Produces:
#   results/stage0/stage-result.json
#   results/env-check.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ITER="1"
VARIANT="baseline"
TASK="test"
RESULTS_DIR="$PROJECT_ROOT/results/stage0"
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

echo "[stage0] Task: $TASK"

case "$TASK" in
  generate)
    echo "[stage0] No generation needed for bootstrap - environment is deterministic"
    jq '.status = "pass"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  test)
    echo "[stage0] Running environment check..."
    COMPILE_LOG="$RESULTS_DIR/compile-log.txt"

    # Run env check
    bash "$PROJECT_ROOT/scripts/env-check.sh" 2>&1 | tee "$COMPILE_LOG"

    ENV_CHECK="$PROJECT_ROOT/results/env-check.json"

    # Read version pins from config
    HW_CONFIG="$CONFIG_DIR/hardware.json"
    TTMETAL_PINNED=$(jq -r '.tt_metal_commit // ""' "$HW_CONFIG")
    TTSIM_PINNED=$(jq -r '.ttsim_version // ""' "$HW_CONFIG")

    SANITY_PASSED=false

    if [ -f "$ENV_CHECK" ]; then
      ALL_READY=$(jq -r '.all_ready' "$ENV_CHECK")
      ERROR_COUNT=$(jq '.errors | length' "$ENV_CHECK")

      # Check pinned versions if we have the repos
      if [ -d "$PROJECT_ROOT/external/tt-metal/.git" ]; then
        ACTUAL_COMMIT=$(cd "$PROJECT_ROOT/external/tt-metal" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        if [ "$ACTUAL_COMMIT" != "$TTMETAL_PINNED" ]; then
          echo "[stage0] WARNING: tt-metal commit $ACTUAL_COMMIT != pinned $TTMETAL_PINNED"
        fi
      fi

      # Run sanity test: compile a minimal kernel with ttsim
      if [ -f "$PROJECT_ROOT/external/ttsim/libttsim_bh.so" ]; then
        echo "[stage0] Running sanity test: compile reference kernel..."
        SANITY_LOG="$RESULTS_DIR/sanity-test.log"
        SANITY_KERNEL="$PROJECT_ROOT/test/reference-kernels/dram-loopback.cpp"
        if [ -f "$SANITY_KERNEL" ]; then
          TT_METAL_HOME_VAL=$(jq -r '.env.TT_METAL_HOME' "$HW_CONFIG")
          TT_METAL_HOME_VAL="${TT_METAL_HOME_VAL/\$\{PROJECT_ROOT\}/$PROJECT_ROOT}"
          TTSIM_VAL=$(jq -r '.env.TT_METAL_SIMULATOR' "$HW_CONFIG")
          TTSIM_VAL="${TTSIM_VAL/\$\{PROJECT_ROOT\}/$PROJECT_ROOT}"

          export TT_METAL_HOME="$TT_METAL_HOME_VAL"
          export TT_METAL_SIMULATOR="$TTSIM_VAL"

          SANITY_BUILD="g++ -std=c++20 -O2 -g -fno-omit-frame-pointer \
            -I$TT_METAL_HOME -I$TT_METAL_HOME/tt_metal \
            -o $RESULTS_DIR/sanity_test $SANITY_KERNEL \
            -L$TT_METAL_HOME/build/lib -ltt_metal \
            -L$(dirname "$TTSIM_VAL") -lttsim_bh -lpthread -ldl"

          if eval "$SANITY_BUILD" >> "$SANITY_LOG" 2>&1; then
            echo "[stage0] Sanity test: compilation OK"
            SANITY_PASSED=true
          else
            echo "[stage0] Sanity test: compilation FAILED (see $SANITY_LOG)"
            result=$(jq --arg log "$SANITY_LOG" '.errors += ["sanity_compile: failed - see " + $log]' <<< "$(cat "$ENV_CHECK")")
            echo "$result" > "$ENV_CHECK"
          fi
        fi
      fi

      if [ "$ALL_READY" = "true" ] && [ "$SANITY_PASSED" = true ]; then
        echo "[stage0] All tools ready, sanity passed"
        jq --arg log "$COMPILE_LOG" \
           '.status = "pass" | .artifacts.compile_log = $log |
            .metrics.tools_ready = 1 | .metrics.error_count = 0 |
            .metrics.sanity_passed = true' \
           "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
      else
        # Merge env errors and sanity errors
        if [ "$SANITY_PASSED" = false ]; then
          ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
        echo "[stage0] Missing $ERROR_COUNT item(s)"
        jq --arg log "$COMPILE_LOG" \
           --argjson ec "$ERROR_COUNT" \
           --argjson sp "$SANITY_PASSED" \
           '.status = "fail" | .artifacts.compile_log = $log |
            .metrics.tools_ready = 0 | .metrics.error_count = $ec |
            .metrics.sanity_passed = $sp' \
           "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"

        jq -c '.errors[]' "$ENV_CHECK" 2>/dev/null | while read -r err; do
          err_name=$(echo "$err" | sed 's/[^a-zA-Z0-9]/_/g')
          echo "$err" > "$RESULTS_DIR/test-suite/failed-tests/$err_name.json"
        done
      fi
    else
      echo "[stage0] env-check.json not produced"
      jq '.status = "error"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    fi
    ;;

  bench)
    echo "[stage0] No benchmark for bootstrap stage"
    jq '.status = "skipped"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    ;;

  *)
    echo "[stage0] Unknown task: $TASK"
    jq '.status = "error"' "$STAGE_RESULT" > tmp.$$ && mv tmp.$$ "$STAGE_RESULT"
    exit 2
    ;;
esac

exit 0
