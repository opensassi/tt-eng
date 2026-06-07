# `mmul` / `MVMUL` – Matrix Multiply (FPU)

**Category:** Matrix Engine (FPU)

**FPU mnemonic:** `MVMUL`

**Syntax:**
```c
TT_MVMUL(FlipSrcB, FlipSrcA, BroadcastSrcBRow, AddrMod, DstRow)
```

**Operation:** `for i in 0..7: for j in 0..15: Dst[DstRow+i][j] += (SrcB[8×16] × SrcA[16×16])[i][j]`

Tile-level matrix multiply: an aligned 8×16 matrix from `SrcB` is multiplied with an aligned 16×16 matrix from `SrcA`, and the resultant 8×16 matrix is added element-wise to an aligned 8×16 block of `Dst`. To get `Dst = A × B` (non-accumulating), use `ZEROACC` prior to `MVMUL`.

**x86 Equivalent:** `tdpbf16ps` / `tdpbssd` (AMX/TILE)

**Data type combinations:**

| Dst data type | += | SrcB data type | @ | SrcA data type |
|---|---|---|---|---|
| 8×16 FP32 or BF16 | += | 8×16 TF32 or BF16 | @ | 16×16 TF32 or BF16 |
| 8×16 FP32 or FP16 | += | 8×16 FP16 | @ | 16×16 FP16 |
| 8×16 integer "32" | += | 8×16 integer "8" | @ | 16×16 integer "8" |

**Registers:**
- **SrcA**, **SrcB** – 2-bank staging buffers (64 rows × 16 cols × 19-bit each). Loaded via Unpacker 0/1.
- **Dst** – 1024×16 16-bit or 512×16 32-bit accumulator register file.
- **RWCs** – Auto-incrementing row counters (`Dst`, `SrcA`, `SrcB`, `FidelityPhase`). Configured via `SETRWC`/`INCRWC`.

**Latency and Throughput:**

| Instruction | Throughput (instr/cycle) | Latency (cycles) |
|---|---|---|
| `MVMUL`, 1 fidelity phase | 1 | 5 |
| `MVMUL`, 2 fidelity phases | 0.5 | 5 per phase |
| `MVMUL`, 3 fidelity phases | 0.33 | 5 per phase |
| `MVMUL`, 4 fidelity phases | 0.25 | 5 per phase |

The number of fidelity phases depends on input precision. INT8 inputs require up to 4 phases; BF16/TF32 typically 1-2 phases.

**Example:**
```asm
; Configure row counters for a 32×32 tile multiply
SETRWC 0, 0, 0, 0     ; Reset Dst, SrcA, SrcB rows

; Unpack input tiles into SrcA and SrcB (handled by UNPACR)
UNPACR ...              ; Load tile A from L1 → SrcA bank 0
UNPACR ...              ; Load tile B from L1 → SrcB bank 0

; Perform multiply (1 fidelity phase, no bank flip)
ZEROACC                 ; Clear Dst accumulator
MVMUL 0, 0, 0, 0, 0    ; Dst[0:7] += SrcB[0:7] × SrcA[0:15]

; Read result from Dst → LReg → Pack to L1
SFPLOAD 0, 1            ; Load Dst row 0-3 → LReg[1]
PACR ...                ; Pack Dst → L1
```

**Interaction with other units:**
- Requires prior `UNPACR` to load SrcA/SrcB banks (Unpacker 0 → SrcA, Unpacker 1 → SrcB).
- After `MVMUL`, use `SFPLOAD` to move Dst → LReg, or `PACR` to pack Dst → L1.
- Use `ZEROACC` before `MVMUL` for non-accumulating multiply.
- Dst write-to-read hazard: 4-cycle stall if same 8×16 Dst block is read after write. Software should loop over ≥5 distinct Dst blocks to avoid stalls.
- Bank flip (`FlipSrcA`/`FlipSrcB`) allows double-buffering: the instruction can flip SrcA/SrcB banks and release the old bank to the Unpackers.

**Fidelity phases:** Each fidelity phase selects different mantissa/magnitude bits for multiplication. The number of phases required depends on data type and desired precision. For floating-point, additional phases recover mantissa bits discarded by prior phases. Each phase is a separate `MVMUL` instruction targeting the same Dst block. The `RWCs.FidelityPhase` auto-increments across phases.

**Integer fidelity phase requirements:**

| | SrcA range | SrcB range | Phases needed |
|---|-----------|-----------|:---:|
| | abs ≤ 31 | abs ≤ 15 | 1 |
| | abs ≤ 31 | abs > 15 | 2 |
| | abs > 31 | abs ≤ 15 | 2 |
| | abs > 31 | abs > 15 | 4 |

**TFLOP/s performance:**

| Instruction | 1 phase | 2 phases | 3 phases | 4 phases |
|---|---|---|---|---|
| MVMUL (no broadcast) | 4.096 TFLOP/s | 2.048 | 1.366 | 1.024 |
| MVMUL (broadcast) | 0.560 TFLOP/s | 0.280 | 0.187 | 0.140 |

**Notes:**
- Matrix operations on Tensix always go through the FPU.
- The distinction between multiply and multiply-accumulate is a configuration difference (`ZEROACC` before multiply).
- Denormal inputs/outputs flushed to zero. NaN/infinity handling does not conform to IEEE754.
- Source bank switching: `FlipSrcA=1` automatically releases SrcA bank to Unpackers and switches to the other bank.
- `BroadcastSrcBRow` mode broadcasts a 1×16 row of SrcB into 7 rows (not 8) with alternating zero rows: rows 0,2,4,6 get the broadcast value, rows 1,3,5 are zero.
- **INT8 SrcA footnote:** For INT8 SrcA, the most significant two bits of magnitude are ignored in multiplication, leaving just the low 8 bits. Usable values are therefore -255..+255, not full INT8 range.
- **FP16/TF32 SrcA footnote:** For SrcA in FP16 or TF32, the least significant mantissa bit is ignored in multiplication.
- **Wait gate behavior:** MVMUL stalls at Wait Gate until SrcA bank and SrcB bank are owned by Matrix Unit (AllowedClient == MatrixUnit).
- **Config register interaction:** Data format is determined by ALU_ACC_CTRL (Fp32_enabled for Dst width, INT8_math_enabled for INT8 mode), ALU_FORMAT_SPEC_REG registers, and on BH, implied format from Unpackers.
- **Dst scheduling: loop order:** When using multiple fidelity phases, the fidelity loop should be the OUTER loop and the Dst block loop should be the INNER loop to avoid stalls.
- **CLR_DVALID guard bits:** Bank flip only releases the bank to Unpackers if CLR_DVALID_SrcA/B_Disable is not set.
