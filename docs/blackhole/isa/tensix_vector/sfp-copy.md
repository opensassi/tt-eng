# `SFPMOV` – Register Copy (Mode)

**Category:** SFPU Data Movement

**Syntax:** `SFPMOV 0, VC, VD, Mod1` (copy mode)

**Operation:** `for lane in 0..31: VD[lane] = VC[lane]`

**Latency:** 1 cycle, IPC=1

**Backend:** simple sub-unit

**Register constraint:** VD must be < 8 or == 16

**ALL_LANES_ENABLED mode:** Mod1 bit 1 (SFPMOV_MOD1_ALL_LANES_ENABLED=2) bypasses the lane-enable mask, forcing all lanes to be written.

**Reserved bit:** Mod1 bit 2 is reserved — NonContractualBehavior (silently cleared on current silicon)

**x86 Equivalent:** `vmovaps`

**Cross-reference:** Other SFPMOV modes: negate (sfp-neg.md), config read (sfp-config-read.md), PRNG (sfp-prng.md)

**Example:**
```asm
SFPMOV 0, 2, 3, MOD_COPY   ; LReg[3] = LReg[2]  (register copy, SFPMOV with copy Mod1)
```
