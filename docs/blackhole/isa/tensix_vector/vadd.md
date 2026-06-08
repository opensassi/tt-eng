# `vadd` – Vector Add (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPADD`

**Syntax:** `SFPADD VA, VB, VC, VD, Mod1` where VA=10

**Operation:** `for lane in 0..31: VD[lane] = ±(1.0 × VB[lane]) ± VC[lane]`

Performs elementwise FP32 addition of two source vectors. The sign of the product (1.0 × VB) and the sign of VC are controlled by Mod1.

**x86 Equivalent:** `vaddps` (AVX2)

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPADD 10, 1, 2, 0, 0   ; LReg[0] = LReg[1] + LReg[2]
