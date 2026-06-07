# Performance Characteristics

## Cycle Counts for Common Operations

| Operation | Cycle estimate | Notes |
|-----------|:---:|-------|
| SFPU vector add (32-wide FP32) | 2 | Pipelined, IPC=1 |
| SFPU vector multiply-accumulate | 2 | `SFPMAD`, 32-wide |
| SFPU vector load from LReg/Dst | 1 | `SFPLOAD` |
| SFPU vector store to LReg/Dst | 1 | `SFPSTORE` |
| SFPU lane-wise compare | 1 | `SFPGT` / `SFPLE` / `SFPLZ` |
| SFPU shift/rotate | 1 | `SFPSHFT`, lanewise |
| Matrix multiply 32×32 (INT8) | Not specified | Depends on FPU pipeline depth |
| NoC read (adjacent core, 512 bits) | ~19 cycles | 5 + 9 + 5 |
| NoC read (distant core, 512 bits) | ~50-200 cycles | Depends on hop count |
| DRAM random access | ~300-400 cycles | NoC + DRAM controller latency |
| Baby RISC-V load (L0 cache hit) | 2 cycles | From local data RAM |
| Baby RISC-V load (L1, no bank conflict) | ≥8 cycles | L0 miss penalty |
| Baby RISC-V integer multiply | 2 cycles | `mul` via EX2 |
| Baby RISC-V integer divide | 6-33 cycles | Data-dependent |
| Branch mispredict | 5 cycles | 4-cycle bubble + 1 EX1 |

## Bandwidth

| Interface | Bandwidth | Notes |
|-----------|:---:|-------|
| GDDR6 aggregate | 448 GB/s | 28-32 GiB capacity |
| NoC per link (512-bit @ 1.35 GHz) | 86.4 GB/s | Theoretical peak per direction |
| NoC aggregate (two NoCs) | 172.8 GB/s | Full-chip bisection |
| PCIe 5.0 x16 | 64 GB/s | Host-to-device (theoretical) |
| Ethernet per link | 400 Gb/s | 50 GB/s, 14 links = 700 GB/s total |
| L1 SRAM bandwidth (per Tensix core) | Not specified | 16 banks × 128-bit @ 1.35 GHz |

## Latency Tables

### Memory Access Latency

| Access path | Latency (cycles) | Notes |
|-------------|:---:|-------|
| L1 load (L0 data cache hit) | 2 | Fastest path |
| L1 load (L0 miss, no bank conflict) | ≥8 | L1 bank access |
| L1 load (bank conflict) | ≥8 + stall | Bank busy |
| L1 atomic operation | ≥12 | Read-modify-write |
| Local data RAM (fast path) | 2 | Per-core private, no contention |
| Local data RAM (slow path) | ≥8 | NoC-accessible mapping |

### NoC Transfer Latency

| Route | Latency (cycles) |
|-------|:---:|
| NIU → local router | ~5 |
| Router → neighbor router (per hop) | 9 |
| Router → local NIU | ~5 |
| Adjacent core (1 hop) | ~19 |
| 2 hops | ~28 |
| 4 hops | ~46 |
| 8 hops | ~82 |
| Cross-chip worst case | ~100-200 |

### DRAM Access

| Type | Latency (cycles) |
|------|:---:|
| Sequential read (page hit) | ~300-350 |
| Random read (page miss) | ~350-400 |
| Write | ~300-350 |

## Bottlenecks

1. **DRAM bandwidth**: 448 GB/s is shared across 140 Tensix cores. At 32-wide SIMD, one core can saturate the L1-to-compute pipeline; DRAM bandwidth becomes the bottleneck for data-intensive pipelines.

2. **NoC congestion**: Cross-chip communication through shared NoC routers creates contention. Aggregation stages (merge/fan-in) can be NoC-bound.

3. **Serial CABAC**: Entropy coding on Tensix is difficult to parallelize. The L2CPU x280 cores handle this, but serial throughput becomes a bottleneck for video encoding.

4. **DRAM bank conflicts**: Non-sequential access patterns cause page misses, reducing effective bandwidth.

5. **L1 capacity**: 1.5 MiB per core limits tile size for large kernels. Circular buffer allocation must be carefully budgeted.

## Roofline Model

Blackhole Tensix cores are typically:
- **Compute-bound** for dense matrix operations (matmul, conv) at high arithmetic intensity
- **Memory-bound** for elementwise operations (add, relu, scale) with low arithmetic intensity
- **NoC-bound** for data redistribution, gather/scatter, and cross-core communication
