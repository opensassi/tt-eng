# `mmadd` / `DOTPV` – Matrix Multiply-Accumulate / Dot Product (FPU)

**Category:** Matrix Engine (FPU)

**FPU mnemonic:** `MVMUL` (accumulating) / `DOTPV`

**Syntax:**
```c
TT_MVMUL(FlipSrcB, FlipSrcA, BroadcastSrcBRow, AddrMod, DstRow)   ; matrix multiply-accumulate
TT_DOTPV(...)                                                       ; vector dot product
```

**Operation:**
- **MVMUL**: `Dst[8×16] += SrcB[8×16] × SrcA[16×16]` — tile-level matrix multiply-accumulate.
- **DOTPV**: Dot product of two vectors from SrcA and SrcB, accumulated onto Dst.

Operates on tiles loaded into SrcA and SrcB registers, accumulating results into Dst registers.

**x86 Equivalent:** `tdpbf16ps` / `tdpbssd` (AMX/TILE)

**Data formats:** INT8, INT16, BFLOAT16, TF32, FP16

**Registers:**
- **SrcA** – 64×16×19-bit staging buffer (loaded by Unpacker 0)
- **SrcB** – 64×16×19-bit staging buffer (loaded by Unpacker 1)
- **Dst** – 1024×16-bit or 512×32-bit accumulator register file
- **RWCs** – Auto-incrementing counters for Dst/SrcA/SrcB rows and fidelity phase

**Latency and Throughput:**

| Instruction | Throughput (instr/cycle) | Latency (cycles) |
|---|---|---|
| `MVMUL` (matrix multiply) | 1 (per fidelity phase) | 5 |
| `DOTPV` | 1 (per fidelity phase) | 5 |
| `GAPOOL` (global avg pool) | 1 | 5 |
| `GMPOOL` (global max pool) | 1 | 5 |
| `ELWMUL` (element-wise mul) | 1 (per fidelity phase) | 5 |
| `ELWADD` / `ELWSUB` | 1 | 5 |

**Fidelity phases:** Multiple phases are used to recover precision in floating-point multiply. INT8 inputs typically need 4 phases for full range (±255). The `RWCs.FidelityPhase` counter advances through phases; each phase is a separate instruction targeting the same Dst block.

**Example:**
```asm
; Load input tiles
UNPACR ...              ; Unpack tile A from L1 → SrcA, bank 0
UNPACR ...              ; Unpack tile B from L1 → SrcB, bank 0

; Phase 1 of 2 (BF16 multiply)
MVMUL 0, 0, 0, 0, 0    ; Dst[0:7] += SrcB[0:7] × SrcA[0:15] (phase 0)

; Phase 2 of 2 (recover lower mantissa bits)
MVMUL 0, 0, 0, 1, 0    ; Same Dst block, phase 1 auto-incremented

; Pack result to L1
PACR ...
```

**Interaction with other units:**
- SrcA/SrcB must be loaded via `UNPACR` before matrix instructions.
- After computation, use `SFPLOAD` → `SFPSTORE` for vector post-processing, or `PACR` for direct pack to L1.
- Dst read-after-write hazard: 4-cycle stall on same 8×16 Dst block. Use ≥5 distinct blocks for pipelining.
- Bank flip on `MVMUL` can automatically release SrcA/SrcB banks to Unpackers for double-buffering.

**Notes:**
- Matrix Engine (FPU) documentation shared with Wormhole — similar but not identical behavior.
- Tile dimensions are software-defined (32×32 is common, implemented as 8×16 column-blocks in FPU).
- For pure multiply (no accumulation), use `ZEROACC` before the first `MVMUL`.
- Denormals flushed to zero. NaN/infinity handling is non-IEEE754.
