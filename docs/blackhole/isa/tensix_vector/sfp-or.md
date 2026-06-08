# `SFPOR` – Bitwise OR

**Category:** SFPU Bitwise Logical

**Backend:** Vector Unit (SFPU), simple sub-unit

**Syntax:** `SFPOR VB, VC, VD, Mod1`

**Operation:** `vb = (Mod1 & SFPOR_MOD1_USE_VB) ? VB : VD; LReg[VD] = LReg[vb] | LReg[VC];`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpor`

**Mod1 Values:**
- `0` (default): Destructive — VD is both source and destination (VB ignored, matches Wormhole behavior)
- `1` (`SFPOR_MOD1_USE_VB`): Non-destructive — uses explicit VB as first source operand

**Register Constraints:**
- VD must be < 8 or == 16
- Operation is gated by LaneEnabled per lane (disabled lanes are not modified)

**Examples:**
```asm
SFPOR 0, 1, 2, 0      ; LReg[2] |= LReg[1]  (destructive, Mod1=0, VB ignored)
SFPOR 3, 1, 2, 1      ; LReg[2] = LReg[3] | LReg[1]  (non-destructive 3-operand, Mod1=1)
