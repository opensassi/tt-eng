# `SFPSTOCHRND` – Stochastic Rounding / Vector Pack

**Category:** Data Format Conversion

**Backend execution unit:** Vector Unit (SFPU), round sub-unit. The Packer is a separate downstream stage that handles data movement from Dst register to L1 — it is not part of this instruction.

**Syntax:**

Three distinct C API forms (6 operands each):

```c
// FloatFloat / FloatInt (mantissa reduction or float→int):
TT_SFP_STOCH_RND(RoundingMode, 0, VC, VC, VD, Mod1)

// IntInt (sign-magnitude integer narrowing):
TT_SFP_STOCH_RND(RoundingMode, Imm5, VB, VC, VD, ((UseImm5)<<3)|Mod1)
