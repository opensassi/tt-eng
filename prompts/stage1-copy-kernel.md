# Stage 1: DRAM Loopback Copy Kernel

## Objective

Write a TT-Metalium kernel that copies a 4096-element vector from DRAM buffer A to DRAM buffer B.

## Task Description

Create a C++ TT-Metalium program following the structure of the reference DRAM Loopback example.

## Requirements

1. **Allocate** two DRAM buffers: buffer A (input) and buffer B (output), each with 4096 elements of 4-byte integers
2. **Initialize** buffer A with known test data (sequential integers 0..4095)
3. **Create** a Reader kernel that reads from DRAM buffer A using `noc_async_read`
4. **Create** a Writer kernel that writes to DRAM buffer B using `noc_async_write`
5. **Run** the kernels on ttsim (Blackhole target)
6. **Read back** buffer B and verify it matches buffer A
7. **Print** "PASS" if B matches A, "FAIL: mismatch at index N" if not

## Reference Code Structure

```cpp
#include "tt_metal/impl/device/device.hpp"
#include "tt_metal/impl/program/program.hpp"
#include "tt_metal/impl/buffer/buffer.hpp"
#include "tt_metal/host_api.hpp"
#include "tt_metal/detail/tt_metal.hpp"

using namespace tt::tt_metal;

int main() {
    // 1. Initialize device
    Device *device = CreateDevice(0);

    // 2. Allocate buffers
    // InterleavedBufferConfig for DRAM

    // 3. Create program with reader + writer kernels
    Program program = CreateProgram();

    // 4. Configure circular buffers

    // 5. Set kernel arguments (DRAM addresses, sizes, CB indices)

    // 6. Enqueue commands via CommandQueue

    // 7. Read back and verify

    // 8. Cleanup
    CloseDevice(device);
    return 0;
}
```

## Constraints

- Use slow dispatch mode (TT_METAL_SLOW_DISPATCH_MODE=1)
- No simulator-specific conditionals
- Must compile with g++ -std=c++20
- Must run on Blackhole ttsim without hardware
