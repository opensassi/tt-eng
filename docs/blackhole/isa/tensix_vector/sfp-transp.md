# `SFPTRANSP` – Vector Transpose

**Category:** SFPU Data Movement

**Syntax:** `SFPTRANSP VD`

Modifier fields (Mod0, Mod1) must be 0; reserved field must be 0.

**Operation:** Within each column (8 lanes × 4 rows), transpose `LReg[0:4]` and `LReg[4:8]`. Effectively a 4×4 matrix transpose within each group of 4 vector registers.

Given the 4×8 lane layout (8 columns × 4 rows of lanes), this instruction transposes the 4×4 submatrix in each column of lanes.

The four stacked LRegs form a 3D tensor of shape 4×4×8 lanes; this instruction transposes the two 4-length axes within each column.

**Caution:** Operates column-wise on 4×4 submatrices within an 8-lane group — NOT a general 4×8 or 8×8 transpose.

**Register Constraints:**
- `VD` must be < 12 for the transpose to execute, unless `DISABLE_BACKDOOR_LOAD` is set in `LaneConfig`. Higher `VD` values silently skip the operation.
- Only enabled lanes are affected; disabled lanes retain their values.

**Latency:** ~1 cycle (estimated), IPC=1

**x86 Equivalent:** No single instruction; requires multiple `vperm2i128` / `vpermq` operations

**Backend:** Vector Unit (SFPU) — simple sub-unit

**Blackhole / Wormhole Compatibility:** Behavior is identical on Wormhole and Blackhole.

**Example:**
```asm
; Transpose 4×4 submatrices within each column of lanes
SFPTRANSP R0
