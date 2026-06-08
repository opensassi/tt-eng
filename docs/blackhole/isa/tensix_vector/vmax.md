# `vmax` – Vector Maximum (SFPU)

**Category:** SFPU Vector Arithmetic

**Backend execution unit:** Vector Unit (SFPU)

**SFPU mnemonic:** `SFPSWAP` (maximum mode)

**Syntax:** `SFPSWAP 0, VC, VD, Mod1` (maximum mode, as min/max pair)

**Operation:** Simultaneous with `vmin`: `VD = Min(VC, VD)`, `VC = Max(VC, VD)`.

**x86 Equivalent:** `vmaxps` / `vpmaxud` (AVX2)

**Latency:** 2 cycles

**Throughput:** 1 per 2 cycles (0.5 IPC)

**Example:**
```asm
; LReg[0] = Max(LReg[0], LReg[1]) AND LReg[1] = Min(LReg[0], LReg[1])
SFPSWAP 0, 0, 1, SFPSWAP_MOD1_VEC_MIN_MAX
; LReg[0] now holds the max of original LReg[0] and LReg[1]
