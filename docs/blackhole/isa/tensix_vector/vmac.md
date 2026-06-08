# `vmac` – Vector Multiply-Accumulate (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPMAD`

**Syntax:** `SFPMAD VA, VB, VC, VD, Mod1`

**Operation:** `for lane in 0..31: VD[lane] = ±VA[lane] × VB[lane] ± VC[lane]`

Elementwise FP32 fused multiply-accumulate. The most general SFPU arithmetic instruction.

**Backend execution unit:** Vector Unit (SFPU), MAD sub-unit

**x86 Equivalent:** `vfmadd231ps` / `vfmadd231pd` (AVX2 FMA)

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPMAD 1, 2, 3, 0, 0   ; LReg[0] = LReg[1] × LReg[2] + LReg[3]
