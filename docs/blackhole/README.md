# Blackhole Architecture Documentation

This directory contains extracted and organized documentation from the Tenstorrent ISA documentation repository (`external/tt-isa-documentation/`). It provides the knowledge base needed to make architectural decisions when designing kernels for Blackhole.

## File Index

| File | Content | Use case |
|------|---------|----------|
| `01_architecture_overview.md` | Chip composition, tile types, dataflow philosophy | High-level planning, understanding the target |
| `02_tensix_core_deep_dive.md` | Core components: RISC-V, SFPU, FPU, L1, pipeline | Kernel design, compute mapping |
| `03_l2cpu_and_system_control.md` | SiFive x280 clusters, boot flow, control plane | Serial workloads, scheduling, host comm |
| `04_memory_hierarchy.md` | DRAM, L1, L0, address spaces, alignment | Data layout, buffer allocation, page sizing |
| `05_noc_and_communication.md` | NoC topology, transactions, CBs, ordering | Data flow design, inter-core communication |
| `06_instruction_set_index.md` | Full ISA index with x86 equivalents | Instruction selection, optimization |
| `07_performance_characteristics.md` | Cycle counts, bandwidth, latency tables, bottlenecks | Performance modeling, roofline analysis |
| `08_workload_mapping_guide.md` | Stage placement, L1 budgeting, pipeline examples | Pipeline architecture design |
| `isa/` | Per-instruction detail files | Reference during implementation |

## Usage

For pipeline architecture design:
1. Read `08_workload_mapping_guide.md` for methodology
2. Reference `01_architecture_overview.md` and `02_tensix_core_deep_dive.md` for core capabilities
3. Use `05_noc_and_communication.md` for data flow constraints

For kernel implementation:
1. Read `02_tensix_core_deep_dive.md` for the Baby RISC-V pipeline
2. Reference `06_instruction_set_index.md` → `isa/` files for specific instructions
3. Use `04_memory_hierarchy.md` for address space layout

For performance analysis:
1. Read `07_performance_characteristics.md` for cycle/bandwidth estimates
2. Cross-reference with `05_noc_and_communication.md` for NoC topology limits

## Source

This documentation was generated from the Tenstorrent ISA documentation at:
- `external/tt-isa-documentation/BlackholeA0/` (Blackhole-specific content)
- `external/tt-isa-documentation/WormholeB0/` (shared content, referenced where Blackhole points to it)

ISA documentation repository: https://github.com/tenstorrent/tt-isa-documentation

## Information Completeness

Where specific numbers (latency, bandwidth) are documented in the source material, they are included. Where marked "not specified", the value was absent from the source. Some Wormhole-only NoC details (in `WormholeB0/NoC/`) may differ from Blackhole and are noted.
