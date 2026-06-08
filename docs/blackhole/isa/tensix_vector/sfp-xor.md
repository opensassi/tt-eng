# `SFPXOR` – Bitwise XOR

**Category:** SFPU Bitwise Logical

**Syntax:** `SFPXOR VC, VD`

**Operation:** `for lane in 0..31: if LaneEnabled: VD[lane] ^= VC[lane]`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpxor`

**Backend execution unit:** SFPU simple sub-unit

**Example:**
```asm
SFPXOR 2, 0      ; LReg[0] ^= LReg[2]  (destructive bitwise XOR, all lanes)
