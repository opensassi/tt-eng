# System Context — TT-Metalium Agent Validation Pipeline

## Tenstorrent Programming Model

TT-Metalium programs follow a three-stage pipeline within each Tensix core:

1. **Reader Kernel** — data movement kernel using `noc_async_read` to transfer data from DRAM to circular buffers (CBs)
2. **Compute Kernel** — processes data from CBs using vector engine (SFPU) or matrix engine (FPU)
3. **Writer Kernel** — uses `noc_async_write` to transfer results from CBs back to DRAM

## Circular Buffer (CB) Configuration

CBs are the inter-kernel communication mechanism. Configured via:
- `CircularBufferConfig` with size and data format
- CB indices are addressed as `tt::CBIndex::c_<N>`
- Reader writes to CB, compute reads from CB, writer reads from CB

## Host Program Structure

```
1. Initialize device and program
2. Allocate DRAM/interleaved buffers
3. Create Command Queue (CQ)
4. Configure CBs for inter-kernel communication
5. Create Reader, Writer, and Compute kernels
6. Enqueue buffer writes, kernel runs, buffer reads
7. Verify output
```

## Simulator (ttsim)

- Blackhole target via `libttsim_bh.so`
- Set `TT_METAL_SIMULATOR` env var to .so path
- Use slow dispatch: `TT_METAL_SLOW_DISPATCH_MODE=1`
- SOC descriptor: `blackhole_140_arch.yaml`
- Bit-exact numerical results

## tt-npe Profiler

- Run in Profiler Mode for performance CSV output
- Output columns: `DRAM BW UTIL`, `NOC UTIL`
- Used for quantitative evaluation between optimizations

## Constraints

- No simulator-specific conditionals in generated code
- Build and run identical binaries for simulator and silicon
- Slow dispatch mode only (fast dispatch not yet validated)
