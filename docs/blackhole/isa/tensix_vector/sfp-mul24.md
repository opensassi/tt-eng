# `SFPMUL24` – 23-bit Integer Multiply

**Category:** SFPU Integer Arithmetic

**Syntax:** `SFPMUL24 VA, VB, VC, VD, Mod1`

## Modes

| Mode | Operation |
|------|-----------|
| UPPER=0 (non-UPPER) | `VD = (VA × VB) & 0x7FFFFF` (low 23 bits of 23b×23b product) |
| UPPER=1 | `VD = ((VA & 0x7FFFFF) × (VB & 0x7FFFFF)) >> 23` (high 23 bits) |

**Latency:** 2 cycles, IPC=1

**x86 Equivalent:** `vpmuldq` (limited)

**Example:**
```asm
; 23-bit integer multiply: LReg[2] = (LReg[0] × LReg[1]) & 0x7FFFFF
SFPMUL24 0, 1, 2, 0, MOD_NON_UPPER

; Fixed-point multiply: LReg[2] = LReg[0] × LReg[1] >> 23
SFPMUL24 0, 1, 2, 0, MOD_UPPER
```

**Notes:** New in Blackhole. Used for integer arithmetic (e.g., averaging, scaling).

**WARNING — VC register hazard:** Software is strongly encouraged to turn this operation into a no-op by always setting VC == 9 (constant zero). Non-zero VC triggers **NonContractualBehavior** (undefined hardware behavior). The multiply itself uses only VA, VB and the Mod1 mode; VC must be set to 9 as a safety constraint, not as an operand.
