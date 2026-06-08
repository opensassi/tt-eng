# `vsub` – Vector Subtract (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPADD` (with sign control)

**Syntax:** `SFPADD 10, VB, VC, VD, Mod1` (where VA=10; use SFPMAD when VA != 10)

**Operation:** `for lane in 0..31: VD[lane] = ±(1.0 × VB[lane]) ± VC[lane]`

Elementwise FP32 subtraction achieved via sign-flip modifier on `SFPADD`. The operation uses the partially-fused MAD pipeline: `VD = ±(1.0 × VB) ± VC` with a single rounding step. Denormal VB is flushed to sign-preserved zero before the multiply.

**x86 Equivalent:** `vsubps` (AVX2), `vsubpd`

**Backend execution unit:** Vector Unit (SFPU), MAD sub-unit

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Mod1 Modifiers:**

| Bit | Constant | Description |
|-----|----------|-------------|
| 0   | `SFPMAD_MOD1_NEGATE_VA` (0x1) | Negate VA |
| 1   | `SFPMAD_MOD1_NEGATE_VC` (0x2) | Negate VC |
| 2   | `SFPMAD_MOD1_INDIRECT_VA` (0x4) | Indirect VA from LReg[7] |
| 3   | `SFPMAD_MOD1_INDIRECT_VD` (0x8) | Indirect VD from LReg[7] |

**Example:**
```asm
SFPADD 10, 1, 2, 0, SFPMAD_MOD1_NEGATE_VC   ; LReg[0] = LReg[1] - LReg[2]
