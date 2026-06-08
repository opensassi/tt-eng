# `vmul` – Vector Multiply (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPMUL`

**Syntax:** `SFPMUL VA, VB, VC, VD, Mod1`

**Operation:** `for lane in 0..31: VD[lane] = ±VA[lane] × VB[lane] ± 0`

Elementwise FP32 multiplication with zero additive identity from VC=9 (LReg[9]=0). When VA=10, computes `1.0 × VB`.

**x86 Equivalent:** `vmulps` (AVX2), `vmulpd`

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPMUL 1, 0, 9, 3, 0   ; LReg[3] = LReg[1] × LReg[0]
