# `SFPAND` – Bitwise AND

**Category:** SFPU Bitwise Logical

**Syntax:** `SFPAND VC, VD`

**Operation:** `for lane in 0..31: VD[lane] &= VC[lane]`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpand`

**Example:**
```asm
SFPAND 1, 2      ; LReg[2] &= LReg[1]  (destructive bitwise AND, all lanes)
```

**Note:** Destructive: VD is both source and destination. For a 3-operand AND, first copy VC to scratch, then AND.
