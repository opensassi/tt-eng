# `SFPABS` – Vector Absolute Value

**Category:** SFPU Arithmetic

**Syntax:** `TT_SFPABS(0, VC, VD, Mod1)` → assembler: `SFPABS VC, VD`

**Operation (FP32):** `VD = Abs(VC)`. If VC is NaN, the NaN is passed through (not converted to quiet NaN).

**Operation (int, two's complement):** `VD = Abs(VC)`. If VC is -0, VD = +0. If VC is -2^31, VD = -2^31 (saturated, same as `SFPMOV` Abs).

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vandps` (mask off sign bit)

**Example:**
```asm
SFPABS 1, 0        ; LReg[0] = Abs(LReg[1])  (absolute value, FP32 or two's complement int, all lanes)
```

**Note:** Operates on two's complement integers. For sign-magnitude absolute value, use `SFPSETSGN` instead.
