# `SFPLOAD` – Load Dst → LReg

**Category:** SFPU Data Movement

**Syntax:** `SFPLOAD R, VD`

**Operation:** `VD = Dst[R:R+4, 0:15:2]` or `VD = Dst[R:R+4, 1:16:2]`

Loads 32 lanes from the Dst register file (result of matrix/vector compute) into an LReg vector register. Selects even or odd rows.

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vmovaps` (register-to-register)

**Example:**
```asm
SFPLOAD 0, 1        ; LReg[1] = Dst[0:3, even rows]  (load 32 lanes from Dst rows 0-3)
SFPLOAD 8, 2        ; LReg[2] = Dst[8:11, even rows] (load from Dst rows 8-11)
```

**Register Constraints:**
- Only LReg[0..7] are valid destinations

**Scheduling Hazard:**
- After a Matrix Unit write to Dst, insert ≥3 unrelated Tensix instructions before SFPLOAD reads the same Dst region. Alternatively, use STALLWAIT.
