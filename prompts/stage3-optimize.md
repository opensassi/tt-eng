# Stage 3: Performance Optimization

## Objective

Optimize the elementwise addition kernel from Stage 2 to improve performance metrics as reported by tt-npe and perf.

## Task Description

You are given the profiling data from the Stage 2 kernel. Analyze it and propose specific optimizations.

## Input Data

The following profiling artifacts are available:
- `results/stage2/benchmark/metrics.json` — cycles, instructions, IPC
- `results/stage2/benchmark/tt-npe.csv` — DRAM BW UTIL, NOC UTIL
- `results/stage2/benchmark/perf.stat` — hardware counter summary
- `results/stage2/compile-log.txt` — build flags and output
- `src/generated/stage2/kernel.cpp` — the kernel source

## Optimization Targets

Consider these optimization strategies:

1. **Circular buffer size tuning** — larger CBs reduce NOC transactions
2. **Data format optimization** — use narrower types if precision allows
3. **Kernel fusion** — combine reader+compute or compute+writer kernels
4. **DRAM interleaving** — layout data across DRAM banks for bandwidth
5. **Double buffering** — overlap NOC transfers with computation
6. **Vectorization** — use SFPU vector operations for wider SIMD

## Process

1. Read the profiling data
2. Identify the primary bottleneck (NOC-bound, compute-bound, or memory-bound)
3. Propose one specific optimization with expected impact
4. Generate the modified kernel
5. Run test suite to verify correctness
6. Run benchmark to measure improvement

## Constraints

- Must maintain bit-exact correctness
- Must compile and run on Blackhole ttsim
- Must use slow dispatch mode
- Optimizations must be measurable by tt-npe or perf
