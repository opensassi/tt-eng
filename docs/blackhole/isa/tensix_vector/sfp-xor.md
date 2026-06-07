# `SFPXOR` – Bitwise XOR

**Category:** SFPU Bitwise Logical

**Syntax:** `SFPXOR VC, VD`

**Operation:** `for lane in 0..31: VD[lane] ^= VC[lane]`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpxor`

**Example:**
```asm
SFPXOR 2, 0      ; LReg[0] ^= LReg[2]  (destructive bitwise XOR, all lanes)
```
