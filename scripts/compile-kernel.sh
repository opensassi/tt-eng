#!/usr/bin/env bash
# compile-kernel.sh
# Compile a TT-Metalium kernel program against the built libraries.
#
# Usage: bash scripts/compile-kernel.sh <kernel.cpp> -o <output>
#
# Uses the same flags as the reference kernel Makefile.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TT_METAL_SOURCE="$PROJECT_ROOT/external/tt-metal"
TT_METAL_BUILD="$TT_METAL_SOURCE/build"
TTSIM_DIR="$PROJECT_ROOT/external/ttsim"

CXX="${CXX:-g++}"
CXXFLAGS="-std=c++20 -O2 -g -fno-omit-frame-pointer"

OUTPUT=""
KERNEL_SRC=""

while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUTPUT="$2"; shift 2;;
    -c) CXXFLAGS="$CXXFLAGS -c"; shift;;
    *) KERNEL_SRC="$1"; shift;;
  esac
done

if [ -z "$KERNEL_SRC" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: compile-kernel.sh <kernel.cpp> -o <output>"
  exit 2
fi

INCLUDES=$(cat <<'INCEOF'
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/api
    -I/home/pc/projects/tt/external/tt-metal/build/tt_metal/api
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/api/tt-metalium
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/hostdevcommon/api
    -I/home/pc/projects/tt/external/tt-metal
    -I/home/pc/projects/tt/external/tt-metal/tt_stl/.
    -I/home/pc/projects/tt/external/tt-metal/tt_metal
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/impl/.
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/impl/debug
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/impl/profiler
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/hw/inc
    -I/home/pc/projects/tt/external/tt-metal/build/tt_metal/impl
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/common
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/llrt/.
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/fabric
    -I/home/pc/projects/tt/external/tt-metal/tools/scaleout
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/third_party/umd/device/api
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/third_party/tracy/public
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/fmt/69912fb6b71fcb1f7e5deca191a2bb4748c4e7b6/include
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/enchantum/2fb7ab238e36c101b9848892ddb6382276b65837/enchantum/include
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/nlohmann_json/798e0374658476027d9723eeb67a262d0f3c8308/include
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/reflect/f93e77475670eaeacf332927dfe8b50e3f3812e0
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/tt-logger/d2339ce68562cae34cd95f3fece7fd94eb0529b7/include
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/spdlog/b1c2586bb5c35a7929362e87f62433eb68206873/include
    -I/home/pc/projects/tt/external/tt-metal/build/tt_metal/impl/experimental/disaggregation
    -I/home/pc/projects/tt/external/tt-metal/tt_metal/third_party/umd/src/firmware/riscv
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/simd-everywhere/b3b426f78574ef837b17f42e86bab88314c5e4db
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/taskflow/52063f60902bfeb362fa4616b1394ab5efe30994
    -I/home/pc/projects/tt/external/tt-metal/.cpmcache/flatbuffers/2c4062bffa52fa4157b1b4deeae73395df475fda/include
    -I/usr/lib/x86_64-linux-gnu/openmpi/include
INCEOF
)

DEFINES=$(cat <<'DEFEOF'
    -DFMT_HEADER_ONLY=1
    -DSPDLOG_COMPILED_LIB
    -DSPDLOG_FMT_EXTERNAL
    -DTRACY_ENABLE
    -DTRACY_IMPORTS
    -DTT_UMD_BUILD_SIMULATION
DEFEOF
)

LDFLAGS=$(cat <<'LDEOF'
    -L/home/pc/projects/tt/external/tt-metal/build/tt_metal
    -L/home/pc/projects/tt/external/tt-metal/build/tt_metal/third_party/umd/lib
    -L/home/pc/projects/tt/external/tt-metal/build/lib
    -L/home/pc/projects/tt/external/tt-metal/build/tt_stl
    -L/home/pc/projects/tt/external/ttsim/src/_out/release_bh
    -L/usr/lib/x86_64-linux-gnu/openmpi/lib
    -Wl,-rpath,/home/pc/projects/tt/external/tt-metal/build/tt_metal
    -Wl,-rpath,/home/pc/projects/tt/external/tt-metal/build/tt_metal/third_party/umd/lib
    -Wl,-rpath,/home/pc/projects/tt/external/tt-metal/build/lib
    -Wl,-rpath,/home/pc/projects/tt/external/tt-metal/build/tt_stl
    -Wl,-rpath,/home/pc/projects/tt/external/ttsim/src/_out/release_bh
LDEOF
)

LIBS="-ltt_metal -ltt-umd -ltt_stl -ltracy -lttsim -lpthread -ldl -lrt -lz -lhwloc -lnuma -lmpi -lmpi_cxx"

echo "[compile] $KERNEL_SRC -> $OUTPUT"
$CXX $CXXFLAGS $DEFINES $INCLUDES -o "$OUTPUT" "$KERNEL_SRC" $LDFLAGS $LIBS 2>&1
