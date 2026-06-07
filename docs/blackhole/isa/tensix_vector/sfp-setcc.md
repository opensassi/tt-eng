# `SFPSETCC` – Set Per-Lane Condition Codes

**Category:** SFPU Conditional Execution

**Syntax:** `SFPSETCC VC, VD, Mod1`

**Operation:** Sets per-lane `LaneFlags` based on sign/zero of `VC`, depending on mode:
- `VC < 0`, `VC != 0`, `VC >= 0`, `VC == 0` (FP32, sign-mag int, or sign bit)
- For FP32: NaN and -0 handled specially

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vcmpps` → `vmovmskps` sequence (approximate)

**Example:**
```asm
SFPSETCC 1, 2, MOD_SIGN   ; Set LaneFlags where LReg[1] < 0
SFPENCC ON                 ; Enable predication using flags
SFPMUL ...                 ; Only executed on lanes where LReg[1] < 0
SFPPOPC                    ; Restore
```
