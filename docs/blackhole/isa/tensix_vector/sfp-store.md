# `SFPSTORE` – Store LReg → Dst

**Category:** SFPU Data Movement

**Syntax:** `SFPSTORE R, VD`

**Operation:** `Dst[R:R+4, 0:15:2] = VD` or `Dst[R:R+4, 1:16:2] = VD`

Stores LReg vector register to Dst (for subsequent pack to L1 or matrix reuse).

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vmovaps`

**Example:**
```asm
SFPSTORE 0, 1       ; Dst[0:3, even rows] = LReg[1]  (store 32 lanes to Dst rows 0-3)
```

**Scheduling Hazard:**
- After a Matrix Unit write to Dst, insert ≥3 unrelated Tensix instructions before SFPSTORE reads the same Dst region. Alternatively, use STALLWAIT.

**NaN/Inf Behavior (FP16/BF16 conversion modes):**
- When converting to FP16, NaN is converted to infinity — avoid NaN inputs for FP16 conversion
- When converting to BF16, mantissa truncation can turn some NaN values into infinity; canonical NaNs produced by arithmetic instructions do not suffer truncation
