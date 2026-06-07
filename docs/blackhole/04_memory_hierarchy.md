# Memory Hierarchy

## Overview

Blackhole has a heterogeneous memory hierarchy with explicit software management for Tensix cores and conventional cache-coherent memory for L2CPU cores.

## DRAM

- **Type**: GDDR6
- **Capacity**: 28 GiB (p100) / 32 GiB (p150)
- **Bandwidth**: 448 GB/s aggregate
- **Organization**: 24 DRAM tiles, each controlling 4 GiB. Groups of 3 tiles expose the same 4 GiB identically.
- **Access**: Through NoC reads/writes initiated from Tensix or L2CPU cores
- **Latency**: ~300-400 cycles from a Tensix core (specified)
- **Page size**: 4 KiB (typical for NoC transactions)

## L1 Scratchpad (Tensix Core)

| Property | Value |
|----------|-------|
| Capacity | 1536 KiB per Tensix tile |
| Type | Software-managed SRAM (not a cache) |
| Banks | 16 |
| Data path | 128 bits per bank |
| Address range | `0x0000_0000` to `0x0017_FFFF` |
| Access via NoC | Yes (accessible from any tile) |
| Latency (local load) | 2 cycles (L0 hit) / ≥8 cycles (L0 miss, bank conflict) |

**Partitioning** (software-defined):
- Circular buffers (primary consumer)
- Kernel code and read-only data
- Stack and thread-local variables
- Scratch workspace

## L0 Caches (Baby RISC-V)

- **L0 data cache**: 64 bytes (4 lines × 16 bytes) per core. Tiny, not coherent, flushed by fence/atomic.
- **L0 instruction cache**: Small cache between core and L1. Can fuse `.ttinsn` instructions in T-cores.
- Both are transparent to software but affect performance.

## Local Data RAM (Baby RISC-V)

| Core | Size | Fast address | Slow address |
|------|:---:|:---:|:---:|
| B, NC | 8 KiB | `0xFFB0_0000` | `0xFFB1_4000-5FFF` |
| T0, T1, T2 | 4 KiB | `0xFFB0_0000` | Various `0xFFB1_8000-DFFF` |

Fast access: 2-cycle latency, no contention. Slow access: ≥8-cycle latency, suffers contention.

## L2CPU Cache Hierarchy

| Cache | Size | Type |
|-------|:---:|------|
| L1I | 32 KiB private | Virtually-indexed, physically-tagged |
| L1D | 32 KiB private | Virtually-indexed, physically-tagged |
| L2 | 128 KiB private | Unified |
| L3 | 2 MiB shared per 4-core cluster | Unified |

## Address Spaces

| Space | Range | Description |
|-------|-------|-------------|
| L1 SRAM | `0x0000_0000` - `0x0017_FFFF` | Tensix core scratchpad (NoC-accessible) |
| Local data RAM | `0xFFB0_0000` - `0xFFB0_0FFF` | Per-core fast private RAM |
| Local data RAM (slow) | `0xFFB1_4000` - `0xFFB1_DFFF` | Per-core RAM via NoC-accessible path |
| NoC registers | `0xFFB2_0000` - `0xFFB3_FFFF` | NoC 0 and NoC 1 MMIO control |
| NoC overlay | `0xFFB4_0000` - `0xFFB7_FFFF` | NoC overlay coprocessor |
| Tensix backend config | `0xFFEF_0000` - `0xFFEF_FFFF` | Coprocessor configuration |
| Tensix Dst | `0xFFBD_8000` - `0xFFBD_FFFF` | Matrix/vector result registers |

## Alignment Rules

- NoC transactions: 16-byte aligned for L1 targets (specified)
- NoC atomic operations: target 128-bit aligned addresses in L1
- DRAM accesses: page-aligned (4 KiB) recommended for bandwidth
- SFPU vector loads: 16-byte aligned (specified)
