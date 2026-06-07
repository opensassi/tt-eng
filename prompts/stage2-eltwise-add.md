# Stage 2: Elementwise Addition Compute Kernel

## Objective

Write a TT-Metalium program that uses a circular buffer (CB) and a compute kernel to add 4096 integers from buffer A and buffer B, storing the result in buffer C.

## Task Description

Extend beyond the copy kernel pattern to include a **compute kernel** that performs elementwise addition on data flowing through circular buffers.

## Requirements

1. **Allocate** three DRAM buffers: A (input), B (input), C (output), each 4096 x 4-byte integers
2. **Initialize** A with 0..4095, B with 4095..0
3. **Configure** CBs: input CB for reader, output CB for compute-to-writer handoff
4. **Create** three kernels:
   - **Reader kernel**: reads A and B from DRAM via `noc_async_read`, writes to input CB
   - **Compute kernel**: reads from input CB, performs elementwise add, writes to output CB
   - **Writer kernel**: reads from output CB, writes result C to DRAM via `noc_async_write`
5. **Run** on ttsim, read back C
6. **Verify** C[i] == A[i] + B[i] for all i

## Circular Buffer Sizing

```
Reader CB: 2 entries x 4096 bytes each (for double buffering)
Output CB: 2 entries x 4096 bytes each
CB data format: UInt32
```

## Compute Kernel Signature

```cpp
// In compute kernel
void kernel_main() {
    // Get CB addresses
    // Loop over tiles/entries
    // Read from input CB
    // Perform addition
    // Write to output CB
}
```

## Constraints

- CB-based data flow is mandatory (no direct DRAM access from compute kernel)
- Use slow dispatch mode
- Must compile and run on Blackhole ttsim
- Output expected: C[i] = A[i] + B[i] for all 4096 elements
