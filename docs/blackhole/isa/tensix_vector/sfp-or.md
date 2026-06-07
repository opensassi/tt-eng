# `SFPOR` – Bitwise OR

**Category:** SFPU Bitwise Logical

**Syntax:** `SFPOR VC, VD`

**Operation:** `for lane in 0..31: VD[lane] |= VC[lane]`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpor`

**Example:**
```asm
SFPOR 1, 2      ; LReg[2] |= LReg[1]  (destructive bitwise OR, all lanes)
```

**Note:** Destructive: VD is both source and destination. For a 3-operand OR, first copy VC to scratch, then OR.
