# Makefile for reference kernel tests
# Uses flags from the existing tt-metal build

TT_METAL_SOURCE := /home/pc/projects/tt/external/tt-metal
TT_METAL_BUILD := $(TT_METAL_SOURCE)/build
TTSIM_DIR := /home/pc/projects/tt/external/ttsim

CXX := g++
CXXFLAGS := -std=c++20 -O2 -g -fno-omit-frame-pointer

INCLUDES := \
    -I$(TT_METAL_SOURCE)/tt_metal/api \
    -I$(TT_METAL_BUILD)/tt_metal/api \
    -I$(TT_METAL_SOURCE)/tt_metal/api/tt-metalium \
    -I$(TT_METAL_SOURCE)/tt_metal/hostdevcommon/api \
    -I$(TT_METAL_SOURCE)/tt_metal/hostdevcommon \
    -I$(TT_METAL_SOURCE) \
    -I$(TT_METAL_SOURCE)/tt_stl/. \
    -I$(TT_METAL_SOURCE)/tt_metal \
    -I$(TT_METAL_SOURCE)/tt_metal/impl/. \
    -I$(TT_METAL_SOURCE)/tt_metal/impl/debug \
    -I$(TT_METAL_SOURCE)/tt_metal/impl/profiler \
    -I$(TT_METAL_SOURCE)/tt_metal/hw/inc \
    -I$(TT_METAL_BUILD)/tt_metal/impl \
    -I$(TT_METAL_SOURCE)/tt_metal/common \
    -I$(TT_METAL_SOURCE)/tt_metal/llrt/. \
    -I$(TT_METAL_SOURCE)/tt_metal/fabric \
    -I$(TT_METAL_SOURCE)/tools/scaleout \
    -I$(TT_METAL_SOURCE)/tt_metal/third_party/umd/device/api \
    -I$(TT_METAL_SOURCE)/tt_metal/third_party/tracy/public \
    -I$(TT_METAL_SOURCE)/.cpmcache/fmt/69912fb6b71fcb1f7e5deca191a2bb4748c4e7b6/include \
    -I$(TT_METAL_SOURCE)/.cpmcache/enchantum/2fb7ab238e36c101b9848892ddb6382276b65837/enchantum/include \
    -I$(TT_METAL_SOURCE)/.cpmcache/nlohmann_json/798e0374658476027d9723eeb67a262d0f3c8308/include \
    -I$(TT_METAL_SOURCE)/.cpmcache/reflect/f93e77475670eaeacf332927dfe8b50e3f3812e0 \
    -I$(TT_METAL_SOURCE)/.cpmcache/tt-logger/d2339ce68562cae34cd95f3fece7fd94eb0529b7/include \
    -I$(TT_METAL_SOURCE)/.cpmcache/spdlog/b1c2586bb5c35a7929362e87f62433eb68206873/include \
    -I$(TT_METAL_BUILD)/tt_metal/impl/experimental/disaggregation \
    -I$(TT_METAL_SOURCE)/tt_metal/third_party/umd/src/firmware/riscv \
    -I$(TT_METAL_SOURCE)/.cpmcache/simd-everywhere/b3b426f78574ef837b17f42e86bab88314c5e4db \
    -I$(TT_METAL_SOURCE)/.cpmcache/taskflow/52063f60902bfeb362fa4616b1394ab5efe30994 \
    -I$(TT_METAL_SOURCE)/.cpmcache/flatbuffers/2c4062bffa52fa4157b1b4deeae73395df475fda/include \
    -I/usr/lib/x86_64-linux-gnu/openmpi/include

DEFINES := \
    -DFMT_HEADER_ONLY=1 \
    -DSPDLOG_COMPILED_LIB \
    -DSPDLOG_FMT_EXTERNAL \
    -DTRACY_ENABLE \
    -DTRACY_IMPORTS \
    -DTT_UMD_BUILD_SIMULATION

LDFLAGS := \
    -L$(TT_METAL_BUILD)/tt_metal \
    -L$(TT_METAL_BUILD)/tt_metal/third_party/umd/lib \
    -L$(TT_METAL_BUILD)/lib \
    -L$(TT_METAL_BUILD)/tt_stl \
    -L$(TTSIM_DIR)/src/_out/release_bh \
    -L/usr/lib/x86_64-linux-gnu/openmpi/lib \
    -Wl,-rpath,$(TT_METAL_BUILD)/tt_metal \
    -Wl,-rpath,$(TT_METAL_BUILD)/tt_metal/third_party/umd/lib \
    -Wl,-rpath,$(TT_METAL_BUILD)/lib \
    -Wl,-rpath,$(TT_METAL_BUILD)/tt_stl \
    -Wl,-rpath,$(TTSIM_DIR)/src/_out/release_bh

# Libraries must be after object file for correct linking order
LIBS := \
    -ltt_metal -ltt-umd -ltt_stl -ltracy -lttsim \
    -lpthread -ldl -lrt -lz -lhwloc -lnuma -lmpi -lmpi_cxx

all: dram-loopback eltwise-add

# Static pattern rule: link each target
%: %.cpp
	$(CXX) $(CXXFLAGS) $(DEFINES) $(INCLUDES) -o $@ $< $(LDFLAGS) $(LIBS)

clean:
	rm -f dram-loopback eltwise-add

.PHONY: all clean

clean:
	rm -f dram-loopback eltwise-add

.PHONY: all clean
