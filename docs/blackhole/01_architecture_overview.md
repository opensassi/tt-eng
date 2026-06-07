# Blackhole Architecture Overview

## Chip Composition

The Blackhole ASIC contains the following programmable tiles connected by a 2D torus NoC:

| Component        |   Count (p150)    | Purpose                                                        |
| ---------------- | :---------------: | -------------------------------------------------------------- |
| Tensix tile      | 140 (120 on p100) | Compute and data-movement cores for AI/vector workloads        |
| DRAM tile        |  24 (21 on p100)  | GDDR6 memory controllers, 32 GiB total (28 on p100)            |
| L2CPU tile       |         4         | Coherent clusters of SiFive x280 RISC-V CPUs (16 cores total)  |
| Ethernet tile    |  12 (0 on p100)   | 400 GbE bidirectional links for ASIC-to-ASIC fabric            |
| PCI Express tile |         1         | PCIe 5.0 x16 host interface                                    |
| ARC tile         |         1         | Chip/board management (not customer-programmable)              |
| Security tile    |         1         | Security processor (not customer-programmable)                 |
| NoC              |         2         | Independent networks-on-chip (NoC0, NoC1) connecting all tiles |

## Memory

- **GDDR6**: 28-32 GiB, 448 GB/s bandwidth, exposed through 24 DRAM tiles (each 4 GiB)
- **L1 SRAM**: 1.5 MiB per Tensix core, software-managed scratchpad
- **L2 cache**: 128 KiB private per SiFive x280 core
- **L3 cache**: 2 MiB shared per L2CPU tile cluster

## Dataflow Philosophy

Tenstorrent Blackhole uses an explicit dataflow programming model:

1. **Software-defined pipelines**: Programs specify exact data movement and compute schedules across cores
2. **No hardware cache coherence**: Each Tensix core manages its own L1 scratchpad explicitly
3. **Kernel chaining**: Reader kernels move data from DRAM → L1, compute kernels process, writer kernels store results
4. **Circular buffers**: Primary inter-kernel communication primitive within a core
5. **NoC message passing**: Inter-core communication via explicit NoC reads/writes

## Block Diagram

```
+------------------------------------------------------------------+
|  Blackhole ASIC (2D NoC Torus)                                   |
|                                                                  |
|  +--------+ +--------+ +--------+ +--------+ +--------+ +--------+|
|  | Tensix | | Tensix | | DRAM   | | Tensix | | Tensix | | DRAM  ||
|  | Core 0 | | Core 1 | | Tile 0 | | Core 2 | | Core 3 | | Tile 1||
|  +--------+ +--------+ +--------+ +--------+ +--------+ +--------+|
|  |  NoC Router + NIU (x2: NoC0 + NoC1) per tile                  |
|  +---------------------------------------------------------------+|
|  |  L2CPU Tile 0 | L2CPU Tile 1 | L2CPU Tile 2 | L2CPU Tile 3   ||
|  |  (4x x280)    | (4x x280)    | (4x x280)    | (4x x280)      ||
|  +---------------------------------------------------------------+|
|  |  PCIe Gen5   | Ether 0-3    | Ether 4-7    | Ether 8-11      ||
|  +---------------------------------------------------------------+|
|  |  ARC/Security                                                ||
|  +---------------------------------------------------------------+|
+------------------------------------------------------------------+
```
