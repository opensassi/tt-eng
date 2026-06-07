#!/usr/bin/env bash
set -euo pipefail

# build-tt-metal.sh
# Clones and builds tt-metal and ttsim for the Blackhole target.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXTERNAL_DIR="$PROJECT_ROOT/external"
TT_METAL_DIR="$EXTERNAL_DIR/tt-metal"
TTSIM_DIR="$EXTERNAL_DIR/ttsim"

echo "[build-tt-metal] Starting bootstrap..."

# --- Clone tt-metal ---
if [ ! -d "$TT_METAL_DIR" ]; then
  echo "[build-tt-metal] Cloning tt-metal..."
  git clone --depth 1 https://github.com/tenstorrent/tt-metal.git "$TT_METAL_DIR"
else
  echo "[build-tt-metal] tt-metal already cloned at $TT_METAL_DIR"
fi

# --- Clone ttsim ---
if [ ! -d "$TTSIM_DIR" ]; then
  echo "[build-tt-metal] Cloning ttsim..."
  git clone --depth 1 https://github.com/tenstorrent/ttsim.git "$TTSIM_DIR"
else
  echo "[build-tt-metal] ttsim already cloned at $TTSIM_DIR"
fi

# --- Build ttsim ---
echo "[build-tt-metal] Building ttsim for Blackhole..."
cd "$TTSIM_DIR"
./make.py :build
TTSIM_BUILD="$TTSIM_DIR/src/_out/release_bh/libttsim.so"
if [ ! -f "$TTSIM_BUILD" ]; then
  echo "[build-tt-metal] ERROR: ttsim build failed - libttsim.so not found at $TTSIM_BUILD"
  exit 1
fi
echo "[build-tt-metal] ttsim built successfully: $TTSIM_BUILD"

# --- Build tt-metal ---
echo "[build-tt-metal] Building tt-metal..."
cd "$TT_METAL_DIR"
mkdir -p build
cd build
cmake ..
make -j"$(nproc)" metal_example_add_2_integers_in_riscv
echo "[build-tt-metal] tt-metal build complete"

# --- Set up environment ---
export TT_METAL_HOME="$TT_METAL_DIR"
export TT_METAL_SIMULATOR="$TTSIM_BUILD"
export TT_METAL_SLOW_DISPATCH_MODE=1
export TT_METAL_DISABLE_SFPLOADMACRO=1

# --- Verify with SOC descriptor ---
SOC_DESC="$TT_METAL_HOME/tt_metal/soc_descriptors/blackhole_140_arch.yaml"
SIM_DIR="$(dirname "$TTSIM_BUILD")"
if [ -f "$SOC_DESC" ]; then
  cp "$SOC_DESC" "$SIM_DIR/soc_descriptor.yaml"
  echo "[build-tt-metal] SOC descriptor copied to $SIM_DIR/soc_descriptor.yaml"
else
  echo "[build-tt-metal] WARNING: SOC descriptor not found at $SOC_DESC"
fi

echo "[build-tt-metal] Bootstrap complete."
echo ""
echo "Set these environment variables before running stages:"
echo "  export TT_METAL_HOME=$TT_METAL_DIR"
echo "  export TT_METAL_SIMULATOR=$TTSIM_BUILD"
echo "  export TT_METAL_SLOW_DISPATCH_MODE=1"
echo "  export TT_METAL_DISABLE_SFPLOADMACRO=1"
