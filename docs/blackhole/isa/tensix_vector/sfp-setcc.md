# `SFPSETCC` – Set Per-Lane Condition Codes

**Category:** SFPU Conditional Execution

**Backend:** SFPU simple sub-unit

**Syntax:** `SFPSETCC Imm1, VC, VD, Mod1`

**Operation:** Operating lanewise, performs a comparison `VC < 0` or `VC != 0` or `VC >= 0` or `VC == 0`, and writes the result of the comparison to `LaneFlags`. The elements of the input vector can be any type of 32-bit data, though software should ensure that sign-magnitude integers and FP32 have had negative zero flushed to positive zero.

Comparison uses `int32_t` cast; `-0.0f` maps to `0x80000000` which is `< 0`. Software should flush negative zero to positive zero beforehand. NaN values produce comparison results consistent with their `int32_t` bit pattern.

**Functional model:**
```c
lanewise {
  if (VD < 12 || LaneConfig.DISABLE_BACKDOOR_LOAD) {
    if (LaneEnabled) {
      if (!UseLaneFlagsForLaneEnable) {
        LaneFlags = false;
      } else if (Mod1 & SFPSETCC_MOD1_CLEAR) {
        LaneFlags = false;
      } else if (Mod1 & SFPSETCC_MOD1_IMM_BIT0) {
        LaneFlags = (Imm1 != 0);
      } else {
        int32_t c = LReg[VC].i32;
        switch (Mod1) {
        case SFPSETCC_MOD1_LREG_LT0:  LaneFlags = (c <  0); break;
        case SFPSETCC_MOD1_LREG_NE0:  LaneFlags = (c != 0); break;
        case SFPSETCC_MOD1_LREG_GTE0: LaneFlags = (c >= 0); break;
        case SFPSETCC_MOD1_LREG_EQ0:  LaneFlags = (c == 0); break;
        }
      }
    }
  }
}
