# `SFPTRANSP` – Vector Transpose

**Category:** SFPU Data Movement

**Syntax:** `SFPTRANSP VD`

**Operation:** Within each column (8 lanes × 4 rows), transpose `LReg[0:4]` and `LReg[4:8]`. Effectively a 4×4 matrix transpose within each group of 4 vector registers.

Given the 4×8 lane layout (8 columns × 4 rows of lanes), this instruction transposes the 4×4 submatrix in each column of lanes.

**Caution:** Operates column-wise on 4×4 submatrices within an 8-lane group — NOT a general 4×8 or 8×8 transpose.

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** No single instruction; requires multiple `vperm2i128` / `vpermq` operations

**Notes on cross-lane permute (PSHUFB / VPERM):**
Tensix SFPU has **no single-instruction general cross-lane shuffle** equivalent to x86 `PSHUFB` or `VPERM`. The available cross-lane operations are:
- `SFPTRANSP` – 4×4 register-local transpose (this instruction)
- `SFPSHFT2` – Limited 8-lane-group rotation and shift (see [vshift.md](tensix_vector/vshift.md))
- `XMOV` – Cross-lane data movement in Dst (Matrix Unit; see index)

For a general lane permute (e.g., VPERM2I128), the recommended fallback is:
1. Store vector to Dst via `SFPSTORE`
2. Unpack with address remapping via `UNPACR` (offset row addresses)
3. Load back to LReg via `SFPLOAD`

This sequence adds ~3-4 cycles of latency versus a native shuffle instruction.
