# `vsub` – Vector Subtract (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPADD` (with sign control)

**Syntax:** `SFPADD VA, VB, VC, VD, Mod1` (with appropriate Mod1 sign bits)

**Operation:** `for lane in 0..31: VD[lane] = VB[lane] - VC[lane]`

Elementwise FP32 subtraction. Achieved via sign-flip modifier on `SFPADD`.

**x86 Equivalent:** `vsubps` (AVX2), `vsubpd`

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPADD 10, 1, 2, 0, MOD_SIGN_VC_NEG   ; LReg[0] = LReg[1] - LReg[2]
```

**Notes:** Same pipeline constraints as `vadd`/`SFPADD`.
