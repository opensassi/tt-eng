# `SFPABS` – Vector Absolute Value

**Category:** SFPU Arithmetic — Vector Unit (SFPU), simple sub-unit

**Syntax:** `TT_SFPABS(0, VC, VD, Mod1)` → assembler: `SFPABS VC, VD`

**Operation (FP32):** `VD = Abs(VC)`. If VC is NaN, the NaN is passed through (not converted to quiet NaN).

**Operation (int, two's complement):** `VD = Abs(VC)`. If VC is -0, VD = +0. If VC is -2^31, VD = -2^31 (saturated, same as `SFPMOV` Abs).

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vandps` (mask off sign bit)

**Register Constraints:**
- `VD` must satisfy `VD < 8 || VD == 16` (only LReg[0..7] and LReg[16] are valid destinations). Using an invalid destination produces silent wrong results or crashes.
- Each lane operation is gated by `LaneEnabled`. Disabled lanes retain their previous value.

**Example:**
```asm
SFPABS 1, 0        ; LReg[0] = Abs(LReg[1])  (absolute value, FP32 or two's complement int, all lanes)
