# L2CPU and System Control

## L2CPU Tiles

Blackhole has 4 L2CPU tiles, each containing a coherent cluster of 4 SiFive x280 RISC-V CPUs (16 cores total).

### SiFive x280 Core Details

| Property | Value |
|----------|-------|
| Architecture | 64-bit RISC-V RV64GC |
| Pipeline | Out-of-order, superscalar |
| Branch prediction | Advanced (not simple static like Baby RISC-V) |
| Frequency | ~1.6 GHz |
| L1 data cache | 32 KiB private per core |
| L1 instruction cache | 32 KiB private per core |
| L2 cache | 128 KiB private per core |
| L3 cache | 2 MiB shared per cluster (4 cores) |

### Memory Connectivity

Each L2CPU tile has:
- **Direct DRAM connection**: A dedicated path to a local DRAM tile at a fixed NoC coordinate
  - CPUs 0-3 → DRAM tile D5
  - CPUs 4-7 → DRAM tile D6
  - CPUs 8-15 → DRAM tile D7 (shared)
- **NoC windows**: 256 TLB windows mapping NoC regions into the x280 address space
- **PCIe access**: Via PCI Express tile through NoC windows

### Role in the System

L2CPU cores handle:
- Running the workload scheduler and dispatcher
- Serial workloads unsuitable for dataflow (e.g., CABAC, entropy coding)
- Host communication and control-plane operations
- Initialization and configuration of Tensix cores

### Differences from Tensix Cores

| Aspect | Tensix Core | L2CPU (x280) |
|--------|-------------|--------------|
| Architecture | RV32IM in-order | RV64GC out-of-order |
| Purpose | Dataflow pipeline stage | General-purpose control |
| Memory | Software-managed L1 scratchpad | Cache-coherent hierarchy |
| Programming model | Explicit NoC message passing | Conventional shared memory |
| Vector width | 32-wide SIMD (SFPU) | Standard SIMD (if available) |

## Hardware Reset Notes

- L2CPU harts can only be brought out of reset **once per ASIC power cycle**
- Reset must be done at low L2SYS clock speed, then raised
- An RNMI-based parking mechanism is recommended for runtime hart management

## Boot Flow

1. ARC tile initializes PLLs and clocks
2. BootROM loads initial code
3. L2CPU tiles brought out of reset
4. L2CPU code initializes NoC TLB windows
5. Tensix cores are loaded and released
