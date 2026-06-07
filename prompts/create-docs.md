```markdown
# DOCS_ORGANIZATION.md — Agent Instructions for Analyzing Tenstorrent Blackhole Documentation

## Objective

Analyze the Tenstorrent Blackhole documentation located at `external/tt-isa-documentation/BlackholeA0/` (or the repository root). Extract and organize the information into a structured set of markdown files under `docs/blackhole/`. This knowledge base will be used to make architectural decisions when designing kernels for the location‑aware pipeline model (static pipelines, ring buffers, core adjacency, etc.).

## Output Structure

Create the following files under `docs/blackhole/`.
```

docs/blackhole/
├── 01_architecture_overview.md
├── 02_tensix_core_deep_dive.md
├── 03_l2cpu_and_system_control.md
├── 04_memory_hierarchy.md
├── 05_noc_and_communication.md
├── 06_instruction_set_index.md
├── isa/
│ ├── rv32im/
│ │ └── (only non‑obvious instructions; common ones: just note "standard RV32IM")
│ ├── tensix_vector/
│ │ ├── vadd.md
│ │ ├── vsub.md
│ │ ├── vmul.md
│ │ ├── vmac.md
│ │ ├── vmin.md
│ │ ├── vmax.md
│ │ ├── vavg.md
│ │ ├── vsad.md
│ │ ├── vshift.md
│ │ ├── vpack.md
│ │ └── vunpack.md
│ ├── tensix_matrix/
│ │ ├── mmadd.md
│ │ └── mmul.md
│ ├── data_movement/
│ │ ├── noc_async_read.md
│ │ ├── noc_async_write.md
│ │ ├── noc_async_write_multicast.md
│ │ ├── noc_semaphore_inc.md
│ │ ├── noc_semaphore_wait.md
│ │ ├── dma_read.md
│ │ └── dma_write.md
│ └── circular_buffer/
│ ├── cb_push_back.md
│ ├── cb_wait_front.md
│ └── cb_pop_front.md
├── 07_performance_characteristics.md
└── 08_workload_mapping_guide.md

````

## Step‑by‑Step Instructions

### 1. Locate the Source Documentation

- The documentation is in `external/tt-isa-documentation/` (cloned from https://github.com/tenstorrent/tt-isa-documentation).
- Focus on the `BlackholeA0/` directory. If the structure is flat, scan all relevant `.md` and `.txt` files.

### 2. Extract High‑Level Architecture (File `01_architecture_overview.md`)

- Describe chip composition: number of Tensix cores (140), L2CPU cores (16), DRAM controllers, NoC topology (2D torus, two independent NoCs), Ethernet interfaces, PCIe host interface.
- Explain dataflow philosophy: explicit memory management, software‑defined pipelines, kernel chaining.
- Include a simple block diagram in text (ASCII or Mermaid) if helpful.

### 3. Deep Dive into Tensix Core (File `02_tensix_core_deep_dive.md`)

- Per‑core components:
  - 5 Baby RISC‑V cores (3 compute, 2 data movement)
  - Matrix Engine (FPU) – tile size, operation types
  - Vector Engine (SFPU) – width (16384‑bit), supported ops
  - Local SRAM size (1.5 MB) and its partitioning (circular buffers, workspace, etc.)
  - Instruction buffers, register files.
- Programming model: reader/compute/writer kernels, circular buffers (CBs) as communication primitives.
- Limitations: no hardware cache coherency, limited branch prediction.

### 4. L2CPU and System Control (File `03_l2cpu_and_system_control.md`)

- Describe 16 SiFive X280 cores: out‑of‑order, branch prediction, cache hierarchy (L1, L2, maybe L3), frequency (~1.6 GHz).
- Their role: running scheduler, handling serial work (e.g., CABAC), managing host communication.
- Differences from Tensix cores: general‑purpose vs. dataflow.

### 5. Memory Hierarchy (File `04_memory_hierarchy.md`)

- Per‑core L1 SRAM (1.5 MB) – software managed.
- L2 cache (if any) – likely shared per L2CPU cluster.
- DRAM (28–32 GB GDDR6) – bandwidth 448 GB/s, latency numbers (if documented).
- Memory management: explicit DMA vs. NoC loads/stores, address spaces (DRAM, L1, L2, PCIe).
- Alignment and banking rules.

### 6. NoC and Communication (File `05_noc_and_communication.md`)

- Two NoCs (NoC0 X‑first routing, NoC1 Y‑first routing).
- Virtual coordinates vs. physical coordinates.
- Routing primitives: `noc_async_read`, `noc_async_write`, `noc_async_write_multicast`, `noc_semaphore_inc/wait`.
- Circular buffers (CBs): configuration, limit of 32 per core, memory consumption, global CBs (cross‑core).
- Latency estimates for intra‑chip transfers (core to core), DRAM access, and PCIe.

### 7. Instruction Set Reference (Directory `docs/blackhole/isa/` and Index)

Create a hierarchical reference with an index and per‑instruction detail files.

#### 7.1 Content of `06_instruction_set_index.md`

The index must list all instructions, grouped by category, with:

- Instruction mnemonic
- Brief description (one line)
- x86 equivalent (if any) – e.g., `vadd` → `vpaddd` (AVX2), `vsad` → `psadbw`
- Link to the detailed `.md` file (relative path)

Example:

```markdown
# Tensix Instruction Set Index

## SFPU Vector Instructions (Tensix)

| Instruction | Description | x86 Equivalent | Detail |
|-------------|-------------|----------------|--------|
| `vadd` | Vector integer addition | `vpaddd` / `vpaddw` | [vadd.md](isa/tensix_vector/vadd.md) |
| `vsad` | Sum of absolute differences | `psadbw` (MMX/SSE) | [vsad.md](isa/tensix_vector/vsad.md) |
...
````

#### 7.2 Per‑Instruction File Template

Each detailed instruction file must contain:

````markdown
# `vadd` – Vector Add

**Category:** SFPU Vector Arithmetic

**Syntax:** `vadd dest, src1, src2`

**Operation:** Elementwise addition of two source vectors; result stored in destination.

**x86 Equivalent:** `vpaddd` (AVX2) for 32‑bit, `vpaddw` for 16‑bit.

**Latency:** 1 cycle (pipelined) if data in L1; plus NoC load/store stalls.

**Example:**

```asm
vadd r0, r1, r2   ; r0[i] = r1[i] + r2[i]
```
````

**Usage in VVC:** Motion compensation interpolation filters, DCT.

**Notes:** Vectors must be 16‑byte aligned. Destination must not overlap sources.

```

#### 7.3 Extracting Instructions

- Extract all instruction mnemonics from the documentation (search for `.md` files containing instruction tables or assembly listings).
- For each instruction, capture syntax, operands, latency/throughput (if documented), restrictions.
- If latency is missing, state “not specified”.
- Create a complete ISA reference for all instructions

### 8. Performance Characteristics (File `07_performance_characteristics.md`)

- Cycle counts for common operations: 8x8 DCT, SAD over 64x64, 8‑tap interpolation (if documented; otherwise use literature estimates).
- NoC bandwidth per link, DRAM bandwidth, PCIe 5.0 x16 (64 GB/s).
- Latency tables:
  - L1 SRAM access (1 cycle?)
  - NoC hop (2–3 cycles per core hop)
  - DRAM random access (~300–400 cycles?)
- Bottlenecks: serial CABAC, DRAM bank conflicts, NoC congestion.

### 9. Workload Mapping Guide (File `08_workload_mapping_guide.md`)

Synthesize previous information into actionable advice for designing static pipelines:

- How to decide the number of cores per pipeline stage (based on computational weight and I/O needs).
- Rules for placing stages on adjacent cores (to minimise NoC hops).
- Using global CBs for fan‑in/fan‑out (e.g., 5 ME cores → 1 MC core).
- Double‑buffering pattern for I/O‑bound stages.
- When to use L2CPU vs. Tensix (control vs. data).
- Example mapping for a simple pipeline (e.g., DCT → Quant → InvQuant → InvDCT).

## Process for the Agent

1. **Explore documentation** – List all files under `external/tt-isa-documentation/`. Identify Blackhole‑specific content. Use `grep` or `find` for keywords (“Tensix”, “NoC”, “DRAM”, “instruction”, “cycle”).

2. **Extract and verify** – For each section, read source files, copy essential facts, note ambiguities. If a number is not documented, state “not specified” or derive from context.

3. **Write each markdown file** – Use clear headings, tables, bullet points. Include code blocks for instruction mnemonics. Add cross‑references.

4. **Produce summary** – Create `docs/blackhole/README.md` that lists files and explains usage (e.g., load `01_architecture_overview.md` for high‑level planning, `08_workload_mapping_guide.md` for pipeline design).

## Deliverables

- All files listed above written to `docs/blackhole/`.
- Each file must be substantial (at least 200 words for overview files; per‑instruction files can be shorter).
- The agent must not copy large chunks of original documentation verbatim; summarise and reorganise.

## Execution

The agent will now analyse `external/tt-isa-documentation/BlackholeA0/` and produce the required files. After completion, report a summary of what was found and any missing information.
```
