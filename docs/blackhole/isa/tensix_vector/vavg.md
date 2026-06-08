# `vavg` – Vector Average (SFPU)

**Category:** SFPU Vector Integer Arithmetic

**SFPU mnemonic:** `SFPIADD` + `SFPSHFT` (recommended), or `SFPIADD` + `SFPMUL24`

**Backend:** SFPU (MAD sub-unit)

> **Blackhole-specific:** `SFPMUL24` is new in Blackhole; not available on Wormhole.

**Syntax:**
```asm
SFPIADD 0, 1, 2, MOD_IADD_ADD   ; LReg[2] = LReg[0] + LReg[1]  (32-bit sum)
SFPMUL24 0, 2, 9, 3, 0          ; LReg[3] = LReg[0] * LReg[2]   (VC=9 required)
