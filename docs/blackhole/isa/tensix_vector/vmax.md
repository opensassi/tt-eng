# `vmax` – Vector Maximum (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPSWAP` (maximum mode)

**Syntax:** `SFPSWAP ...` (maximum mode, as min/max pair)

**Operation:** Simultaneous with `vmin`: `VD = Min(VC, VD)`, `VC = Max(VC, VD)`.

**x86 Equivalent:** `vmaxps` / `vpmaxud` (AVX2)

**Latency:** 2 cycles

**IPC:** ≤ 1

**Example:**
```asm
; LReg[0] = Min(LReg[0], LReg[1]) AND LReg[1] = Max(LReg[0], LReg[1])
SFPSWAP 0, 0, 1, 0, MOD_SWAP_MINMAX
; LReg[1] now holds the max of original LReg[0] and LReg[1]
```

**Register Constraints:**
- SFPSWAP uses VC and VD as both source and destination
- VD must be < 12 or DISABLE_BACKDOOR_LOAD must be set

**Instruction Scheduling:**
Same automatic stalling as SFPMAD (2-cycle latency; hardware stalls 1 cycle on RAW hazards)

**Notes:** Computed as a side effect of the same instruction as `vmin`. No separate max-only instruction exists; the max is always obtained alongside the min.

Computed as simultaneous min+max in a single instruction. No standalone max instruction exists.
