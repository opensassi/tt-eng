# Workload Mapping Guide

## Core Design Principles

1. **Minimize NoC hops** — Place pipeline stage pairs on adjacent cores
2. **Maximize L1 utilization** — Keep working sets within 1.5 MiB per core
3. **Overlap compute and data movement** — Double-buffer CBs to hide NoC latency
4. **Avoid DRAM for intermediate results** — Use L1-to-L1 NoC transfers between pipeline stages
5. **Partition work evenly** — Balance compute weight across Tensix cores

## Stage Placement Rules

### Adjacent Core Pipeline

For a linear pipeline (A → B → C → D), place stages on physically adjacent NoC coordinates:

```
Core (0,0) → Core (0,1) → Core (0,2) → Core (0,3)
   Stage A     Stage B     Stage C     Stage D
```

Each hop is ~19 cycles. Data moves core-to-core via NoC, bypassing DRAM.

### Fan-In / Fan-Out Patterns

Use global CBs or NoC multicast for broadcast (one-to-many):

```
          → Core (0,1) Stage B0
Core (0,0) → Core (0,2) Stage B1
  Stage A  → Core (0,3) Stage B2
          → Core (0,4) Stage B3
```

For reduction (many-to-one), use NoC atomic adds:

```
Core (0,1) → Core (0,0)
Core (0,2) → Core (0,0)  →  Accumulate with noc_semaphore_inc
Core (0,3) → Core (0,0)
```

### Double-Buffering Pattern

Each pipeline stage uses 2 input CBs and 2 output CBs:

```
CB_in[0] ← NoC read (async) — data arrives while processing CB_in[1]
CB_in[1] ← NoC read (async) — processed after CB_in[0] is done
```

This hides NoC transfer latency behind computation.

## L1 Budgeting

Out of 1536 KiB per Tensix core:

| Allocation | Typical size | Notes |
|------------|:---:|-------|
| Circular buffers | 512-1024 KiB | Depends on tile count and page size |
| Kernel code/data | 32-128 KiB | Baby RISC-V text + read-only data |
| Stack | 16-32 KiB | Per-core call stack |
| Workspace | 128-512 KiB | Scratch for SFPU/matrix operations |
| Local data RAM | 4-8 KiB | Per-core private, not part of 1536 KiB |

## L2CPU vs Tensix

| Workload type | Run on |
|---------------|:-----:|
| Dense SIMD/matrix compute | Tensix (SFPU/FPU) |
| Data movement / NoC orchestration | Tensix (Baby RISC-V B/NC) |
| Serial control flow | L2CPU (SiFive x280) |
| Entropy coding (CABAC) | L2CPU |
| Scheduling / dispatch | L2CPU |
| Host communication | L2CPU |
| Branch-heavy code | L2CPU |
| Small, irregular workloads | L2CPU |

## Example: Simple Video Processing Pipeline

Mapping a 4-stage pipeline across 4 adjacent Tensix cores:

```
Stage 0: DCT Forward Transform
  Core: (0,0)
  Reader: Load 8×8 blocks from DRAM → CB_in
  Compute: SFPU vector ops for DCT transform
  Writer: Write coefficients to CB_out → NoC to Core (0,1)
  L1 budget: 512 KiB CB_in, 256 KiB CB_out, 128 KiB workspace

Stage 1: Quantization
  Core: (0,1)
  Reader: NoC read from Core (0,0) → CB_in
  Compute: SFPMUL / SFPMAD for quantization
  Writer: Quantized coefficients → CB_out → NoC to Core (0,2)
  L1 budget: 256 KiB CB_in, 256 KiB CB_out, 128 KiB workspace

Stage 2: Entropy Coding (non-CABAC)
  Core: (0,2)
  Reader: NoC read from Core (0,1) → CB_in
  Serialize: RLE / Huffman-like coding on Baby RISC-V
  Writer: Bitstream → CB_out → NoC to Core (0,3)

Stage 3: Bitstream Packing
  Core: (0,3)
  Reader: NoC read from Core (0,2) → CB_in
  Pack: Byte-aligned bitstream assembly
  Writer: Write final bitstream to DRAM

Host → NoC → Core (0,0) → NoC → Core (0,1) → NoC → Core (0,2) → NoC → Core (0,3) → NoC → DRAM
```

Each stage-to-stage transfer avoids DRAM: data stays in L1 and moves via directed NoC messages.

## Core Count Estimation

For a given compute stage:

```
Cores_needed = ceil(work_per_frame / throughput_per_core)
```

Where `throughput_per_core` is bounded by:
- SFPU throughput: 32 operations/cycle at 1.35 GHz = 43.2 GOPS/core
- NoC bandwidth per core: 86.4 GB/s (theoretical, shared)
- L1 capacity: 1.5 MiB

## Performance Optimization Checklist

- [ ] Are pipeline stages on adjacent cores to minimize NoC hops?
- [ ] Are CBs double-buffered to overlap compute and data movement?
- [ ] Is L1 usage within 1.5 MiB per core?
- [ ] Are DRAM accesses minimized for intermediate data?
- [ ] Is the workload balanced across cores (no single hot core)?
- [ ] Are semaphores used for inter-core synchronization?
- [ ] Is the slowest stage identified and optimized first?
- [ ] Are NoC transfers coalesced into large packets (avoid 4-byte transactions)?
- [ ] Is L0 data cache being used effectively (stack/data locality)?
- [ ] Are store coalescing rules respected (16-byte aligned same-region stores)?
