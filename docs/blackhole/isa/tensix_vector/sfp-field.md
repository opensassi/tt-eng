# SFPU Floating-Point Field Manipulation Instructions

## `SFPDIVP2` – Scale by Power of 2

**Syntax:** `SFPDIVP2 VC, VD, Imm8, Mod1`

**Operation:** `VD = {Sign, Exp + Imm8, Mant}` (multiply by 2^Imm8). If VC is NaN/Inf, passthrough (ADD mode only). Alternative mode: `VD = {Sign, Imm8, Mant}`.

**Mod1 constant:** `SFPDIVP2_MOD1_ADD = 1`

**Passthrough:** NaN/Inf passthrough only in ADD mode (Mod1=1). In SET mode (Mod1=0), exponent is replaced unconditionally.

**Exponent wrapping:** Addition wraps: `(Exp + Imm8) & 0xff` (no saturation). Use SFPMULI for saturating scale.

**VD constraint:** VD must be < 8 or == 16.

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit.

**x86 Equivalent:** `vscalefps`

## `SFPSETEXP` – Set Exponent

Set exponent field of VD from various sources (VD's exponent field, Imm8, or VD low 8 bits).

**Mod1 constants:** `SFPSETEXP_MOD1_ARG_IMM = 1`, `SFPSETEXP_MOD1_ARG_EXPONENT = 2`

**Source:** Source of sign+mantissa is VC, source of new exponent is VD's exponent field or Imm8.

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit.

## `SFPSETMAN` – Set Mantissa

Replace mantissa field. Can set from VD mant (low 23 bits) or `Imm12 << 11`.

**Mod1 constant:** `SFPSETMAN_MOD1_ARG_IMM = 1`

**Mantissa source:** Mantissa source is VD's low 23 bits (`b & 0x7fffff`), not from VC.

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit.

## `SFPSETSGN` – Set Sign

Replace sign bit from VD sign or Imm1.

**Mod1 constant:** `SFPSETSGN_MOD1_ARG_IMM = 1`

**Sign sources:** Sign sources are VD's sign bit or Imm1, NOT VC sign. Imm1=0 → Abs, Imm1=1 → NegAbs. Works on both FP32 and sign-magnitude integers.

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit.

## `SFPEXEXP` – Extract Exponent

`VD = VC.Exp` or `VD = VC.Exp - 127`. Can also set lane flags.

**Mod1 constants:** `SFPEXEXP_MOD1_NODEBIAS = 1`, `SFPEXEXP_MOD1_SET_CC_SGN_EXP = 2`, `SFPEXEXP_MOD1_SET_CC_COMP_EXP = 8`

**Flag setting:** Lane flags set when VD < 8: flags = (result < 0), or complement if SET_CC_COMP_EXP is set.

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit.

## `SFPEXMAN` – Extract Mantissa

`VD = {0, !Imm1, VC.Mant}` — extracts mantissa field with padding.

**Mod1 constant:** `SFPEXMAN_MOD1_PAD9 = 1`

**Padding behavior:** PAD9=1 → hidden bit = 0; PAD9=0 → hidden bit = 1<<23.

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit.

All instructions: **Latency 1 cycle, IPC=1**.

**Example:**
```asm
SFPDIVP2 0, 1, 2, 0      ; LReg[1] = LReg[0] × 2^2   (scale by 4)
SFPSETEXP 0, 1, 0x7F, 0  ; LReg[1] = {Sign, 127, Mant}  (set exponent to 0 bias → 1.0 range)
SFPEXEXP 0, 1, MOD_BIAS  ; LReg[1] = Exp(LReg[0]) - 127  (extract unbiased exponent)
SFPEXMAN 0, 1, 0         ; LReg[1] = {0, 0, Mant(LReg[0])} (extract mantissa)
```
