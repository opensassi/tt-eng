# `vmin` – Vector Minimum (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPSWAP` (minimum mode)

**Syntax:** `SFPSWAP ...` (minimum mode)

**Operation:** `for lane in 0..31: { VD[lane] = Min(VC[lane], VD[lane]); VC[lane] = Max(VC[lane], VD[lane]) }`

Simultaneously computes min and max of two vector registers. Min is in VD, max overwrites VC.

**x86 Equivalent:** `vminps` / `vpminud` (AVX2)

**Latency:** 2 cycles

**IPC:** ≤ 1 (shared SFPU resource)

**Example:**
```asm
; LReg[0] = Min(LReg[0], LReg[1]) AND LReg[1] = Max(LReg[0], LReg[1])
SFPSWAP 0, 0, 1, 0, MOD_SWAP_MINMAX
; After: LReg[0] = min(old_LReg[0], old_LReg[1]), LReg[1] = max(old_LReg[0], old_LReg[1])
```

**Register Constraints:**
- SFPSWAP uses VC and VD as both source and destination
- VD must be < 12 or DISABLE_BACKDOOR_LOAD must be set

**Sub-Unit:**
- SFPSWAP executes on the MAD sub-unit of the SFPU

**Instruction Scheduling:**
Same automatic stalling as SFPMAD (2-cycle latency; hardware stalls 1 cycle on RAW hazards)

**Notes:** Computed as side effect of the same instruction as `vmax`. The swap instruction computes both min and max simultaneously in-place. Useful for clamping and sorting networks.
