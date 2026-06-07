# `SFPNOT` – Bitwise NOT

**Category:** SFPU Bitwise Logical

**Syntax:** `SFPNOT VC, VD`

**Operation:** `for lane in 0..31: VD[lane] = ~VC[lane]`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpternlog` (with constant all-ones)

**Example:**
```asm
SFPNOT 0, 1      ; LReg[1] = ~LReg[0]  (bitwise NOT all lanes)
```
