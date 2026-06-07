// kernel-stub.cpp
# Minimal compilable TT-Metalium kernel for Blackhole ttsim.
# Replace the compute section with your logic.
# Compile: g++ -std=c++20 -O2 -g -fno-omit-frame-pointer \
#   -I$TT_METAL_HOME -I$TT_METAL_HOME/tt_metal \
#   -o kernel_test kernel-stub.cpp \
#   -L$TT_METAL_HOME/build/lib -ltt_metal \
#   -L$(dirname $TT_METAL_SIMULATOR) -lttsim_bh \
#   -lpthread -ldl

#include "tt_metal/impl/device/device.hpp"
#include "tt_metal/impl/program/program.hpp"
#include "tt_metal/impl/buffer/buffer.hpp"
#include "tt_metal/host_api.hpp"
#include "tt_metal/detail/tt_metal.hpp"

#include <iostream>
#include <vector>
#include <cstdint>
#include <cstdlib>

using namespace tt::tt_metal;

constexpr std::size_t NUM_ELEMENTS = 4096;
constexpr std::size_t ELEMENT_SIZE = sizeof(int32_t);
constexpr std::size_t BUFFER_SIZE = NUM_ELEMENTS * ELEMENT_SIZE;

int main() {
    Device* device = CreateDevice(0);
    if (!device) {
        std::cerr << "FAIL: Could not create device" << std::endl;
        return 1;
    }

    // Allocate DRAM buffers
    InterleavedBufferConfig buf_config {
        .device = device,
        .size = BUFFER_SIZE,
        .page_size = BUFFER_SIZE,
        .buffer_type = BufferType::DRAM
    };
    auto buffer_a = CreateBuffer(buf_config);
    auto buffer_b = CreateBuffer(buf_config);

    // Initialize input data
    std::vector<int32_t> input_a(NUM_ELEMENTS);
    for (std::size_t i = 0; i < NUM_ELEMENTS; i++) {
        input_a[i] = static_cast<int32_t>(i);
    }
    detail::WriteToBuffer(*buffer_a, input_a);

    // Create program
    Program program = CreateProgram();

    // TODO: Create compute kernel and configure circular buffers
    // reader_kernel: noc_async_read from DRAM to CB
    // compute_kernel: process data from CB to output CB
    // writer_kernel: noc_async_write from CB to DRAM

    // Run
    CommandQueue& cq = device->command_queue();
    EnqueueProgram(cq, program, false);
    Finish(cq);

    // Read back and verify
    std::vector<int32_t> output_b(NUM_ELEMENTS);
    detail::ReadFromBuffer(*buffer_b, output_b);

    bool pass = true;
    for (std::size_t i = 0; i < NUM_ELEMENTS && pass; i++) {
        if (output_b[i] != input_a[i]) {
            std::cerr << "FAIL: mismatch at index " << i
                      << ": expected " << input_a[i]
                      << ", got " << output_b[i] << std::endl;
            pass = false;
        }
    }

    CloseDevice(device);

    if (pass) {
        std::cout << "PASS" << std::endl;
        return 0;
    } else {
        return 1;
    }
}
