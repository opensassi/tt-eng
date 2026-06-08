## 1. Tenstorrent Blackhole Architecture – Key Insights for VVC

### 1.1 Core Composition

- **140 Tensix cores** (data‑plane compute), each with:
  - 5 Baby RISC‑V cores (3 compute, 2 data movement)
  - 1.5 MB local SRAM (software‑managed scratchpad)
  - Wide SIMD vector engine (SFPU, 16,384‑bit) and matrix engine (FPU)
- **16 L2CPU cores** (SiFive x280, general‑purpose, control plane)
- **28–32 GB GDDR6** (448 GB/s)
- **2 independent NoCs** (NoC0 X‑first, NoC1 Y‑first) – torus topology

### 1.2 Bottlenecks and Parallelism Opportunities

- **CABAC is inherently serial** – poorly suited for Tensix SIMD; best run on L2CPU or host CPU.
- **Motion Estimation (ME) dominates compute** (≈45‑50% on CPU) → becomes even more dominant on Tensix because other stages (DCT, quant) are highly parallelisable.
- **Wavefront Parallel Processing (WPP)** gives one independent CABAC engine per CTU row – but only 16 L2CPU cores available → WPP alone underutilises Tensix cores.
- **Overlap WPP across multiple frames (FLP)** – keeps more cores busy, but CABAC remains the ultimate bottleneck.

### 1.3 Memory Hierarchy Fits CTU Processing

- One 64×64 CTU (10‑bit 4:2:0) ≈ 6 KB; search window (±96) ≈ 300 KB. Entire ME task fits in 1.5 MB SRAM. Double‑buffering possible.
- Motion Compensation (MC) is I/O‑bound; requires fetching reference pixel halos (e.g., 23×23 for 8‑tap filter). 5:1 ME:MC core ratio recommended.

### 1.4 Communication Primitives

- **Circular Buffers (CBs)** – primary inter‑kernel communication within a core (32 max per core).
- **Global CBs** – for cross‑core dataflow (e.g., 5 ME cores → 1 MC core).
- **NoC operations** – `noc_async_read/write/multicast`, semaphores for synchronisation.

---

## 2. Lessons from VVenC and x265

### 2.1 VVenC Current State

- Supports frame‑level parallelism (GOP/picture level) but **no CTU‑level WPP**.
- Uses function dispatch tables (scalar, SIMD, assembly) – a pattern we can reuse for Tenstorrent kernel dispatch.

### 2.2 x265 WPP Implementation

- `WaveFront::processRow` – row‑based dependency tracking (left neighbour, above‑right neighbour).
- Row starts after above row’s second CTU completes.
- Provides a reference model for porting WPP to VVenC.

### 2.3 CABAC in VVC

- Three stages: binarisation → context modelling → binary arithmetic coding.
- Context state (`tcs` table) is small (~1 KB) but updated after every bin.
- WPP allows rows to start with state copied from above row’s second CTU.

### 2.4 Incremental Migration Plan (from our discussion)

**Phase 1:** Port individual functions (DCT, ME primitives) to TT‑Metalium kernels, verify via I/O capture against CPU reference.
**Phase 2:** Run serial device encoder (single CTU, no parallelism) using existing VVenC scheduler – maintain bit‑exactness.
**Phase 3:** Introduce WPP + FLP – add dependency tracking, ring buffer queues, and a scheduler on L2CPU. Validate against serial baseline.
**Phase 4:** Offload CABAC to host CPU (via PCIe ring buffers) – keep accelerator scheduler light, host runs CABAC in parallel on many x86 cores.

---

## 3. Agent’s Progress – Test Harness and Documentation

### 3.1 Environment Bootstrap (completed)

- tt-metal and ttsim cloned, built, and pinned to known commits.
- Compilation wrapper (`compile-kernel.sh`) captures all include/link flags.
- Reference kernels (`dram-loopback`, `eltwise-add`) compile and run on `ttsim`.
- Stage scripts (0‑4) produce structured JSON artifacts.

### 3.2 ISA Documentation (61 files)

- Extracted from `tt-isa-documentation` and organised into categories:
  - Architecture overview, Tensix deep dive, L2CPU, memory, NoC.
  - Instruction index and per‑category detail files (SFPU, matrix, data movement, CBs, etc.).
- Currently being enriched with syntax, latency, x86 equivalents, examples, and non‑standard notes (errata, alignment restrictions).

### 3.3 Agent Feedback Loop

- Correctness loop: compile → test → fix (using `compile_error.json` with first 20 lines of compiler stderr).
- Optimisation loop: `tt-npe` metrics (`noc_util_pct`, `dram_bw_util_pct`) drive improvement.
- A/B experiment archive with `compare.py` and `comparison.json`.

---

## 4. Critical Architectural Decisions

- **Static pipeline over dynamic task graph** – avoids global scheduler latency; uses core‑to‑core CBs.
- **CABAC offload to host CPU** – because L2CPU cores are too few (16) and Tensix is a poor fit.
- **Batch transfers at frame level** – to amortise PCIe latency (~10 µs per transaction).
- **Wavefront + frame‑level overlap** – keeps Tensix cores busy while CABAC runs on host.
- **5:1 ME:MC core ratio** – because MC is I/O‑bound and needs continuous feeding.

---

## 5. Next Steps (from your plan)

1. **Complete the ISA audit** – ensure every instruction detail file has syntax, example, latency, and non‑standard notes.
2. **Build the constrained pipeline runner** (Python) – exposes tool calls (`pipeline_create`, `run`, `status`, `compare`) so agent never writes bash.
3. **Test kernel generation** – start with elementwise addition, then 8×8 DCT, then motion estimation primitives.
4. **Gradually enable parallelism** – first WPP on L2CPU (single frame), then FLP (multiple frames), then host CABAC offload.

---

## 6. Summary

Our conversations established that Tenstorrent Blackhole is a promising target for H.266 encoding, but requires careful pipeline design to overcome the CABAC bottleneck and fully utilise 140 Tensix cores. The agent has built a robust test harness and extracted complete ISA documentation. The incremental migration plan – porting functions → serial device encoder → WPP+FLP → host CABAC offload – is sound and de‑risked by stepwise validation. The remaining work is bounded: enrich the instruction reference, implement the pipeline runner, and then let the agent iterate on kernel code with a constrained toolset. The investment in setup will pay off in faster, more reliable kernel generation.
