# `vavg` – Vector Average (SFPU)

**Category:** SFPU Vector Integer Arithmetic

**SFPU mnemonic:** `SFPIADD` + `SFPMUL24` (two instructions)

**Syntax:**
```asm
SFPIADD 0, 1, 2, MOD_IADD_ADD   ; LReg[2] = LReg[0] + LReg[1]  (32-bit sum)
SFPMUL24 0, 2, 3, 9, 0          ; LReg[3] = LReg[0] * LReg[2]   (scale by inverse)
```

**Operation:** Computes average via `(A + B) / 2` implemented as sum then multiply-by-inverse.

The `SFPIADD` computes a 32-bit integer sum: `VD = VC + VD`. Then `SFPMUL24` scales by the inverse of the divisor: `VD = VA × VB / 2^24` (24-bit signed integer multiply with 24-bit fractional result).

For `(A + B) / 2`: use `SFPMUL24` with the constant `0x800000` (representing 0.5 in 1.24 fixed-point).

> **IMPORTANT:** SFPMUL24 VC **must** be 9 (constant zero register). Any non-zero VC triggers NonContractualBehavior. The VC field is the upper 24-bit source; using anything other than the zero register is architecturally unsafe.

> SFPMUL24 is 23b×23b, not 24b — the low 23 bits of the product are retained.

**x86 Equivalent:** `vpavgw` / `vpavgb`

**Latency:** 2 cycles total (1 + 1), fully pipelined

**IPC:** 1 each

**Example:**
```asm
; SAFE: Compute LReg[4] = (LReg[0] + LReg[1]) / 2
SFPLOADI 2, 0x3F00, MOD_BF16    ; LReg[2] = 0.5f (BF16 immediate)
SFPIADD 0, 1, 3, MOD_IADD_ADD   ; LReg[3] = LReg[0] + LReg[1]
SFPMUL24 2, 3, 9, 4, MOD_NON_UPPER ; LReg[4] = (LReg[2] * LReg[3]) & 0x7FFFFF
                                    ; VC=9 (constant zero register) — REQUIRED for safety

; Alternative: shift-based average (rounds toward zero)
SFPIADD 0, 1, 3, MOD_IADD_ADD   ; LReg[3] = LReg[0] + LReg[1]
SFPSHFT 0, 0, 3, 4, 1           ; LReg[4] = LReg[3] >> 1 (arithmetic)
```

**Notes:** Non-standard rounding with `SFPMUL24` approach; use stochastic rounding (`SFPSTOCHRND`) for unbiased results. The shift-based alternative rounds toward zero but is simpler.
