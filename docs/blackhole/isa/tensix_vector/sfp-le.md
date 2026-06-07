# `SFPLE` – Less or Equal (FP32 / Sign-Mag Integer)

**Category:** SFPU Comparison

**Syntax:** `SFPLE VC, VD, Mod1`

**Operation (FP32):** `for lane in 0..31: LaneFlags[lane] = (VD[lane] <= VC[lane])`. Same NaN ordering as SFPGT.

**Operation (sign-mag int):** `VD[lane] = (VD <= VC) ? -1 (0xFFFFFFFF/0x80000001 in sign-mag) : +0`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vcmpps` with LE predicate

**Example:**
```asm
SFPLE 1, 2, 0       ; Set LaneFlags where LReg[2] <= LReg[1]
```

**Mod1 constants:** SET_CC=1, MUTATE_STACK=2, MUTATE_OR=4, SET_VD=8
