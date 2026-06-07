# `SFPLOADMACRO` – Load + Schedule Additional Instructions

**Category:** SFPU Data Movement

**Syntax:** `SFPLOADMACRO R, VD, ExtraInstr1, ExtraInstr2, ExtraInstr3, ExtraInstr4`

**Operation:** Like `SFPLOAD` to load Dst → LReg, but also schedules up to 4 additional SFPU instructions to execute in the same cycle using otherwise-idle sub-units.

SFPU has 5 sub-units: load, simple, MAD, round, store. By default only one is active per cycle. `SFPLOADMACRO` packs the load with other instructions to saturate multiple sub-units.

**Latency:** Complex (depends on chained instructions). Max 4 extra instructions.

**Example:**
```asm
; Load Dst→LReg while simultaneously executing 3 extra instructions in the same cycle
SFPLOADMACRO 0, 1, SFPADD(10, 2, 3, 4, 0), SFPMUL(5, 6, 7, 0), SFPNOP
; Cycle 1: LReg[1] = Dst[0:3]  AND  LReg[4] = LReg[2] + LReg[3]  AND  LReg[0] = LReg[5] × LReg[6]
```

**Notes:** `TT_METAL_DISABLE_SFPLOADMACRO=1` disables this instruction on ttsim (unsupported in SFPU simulator).
