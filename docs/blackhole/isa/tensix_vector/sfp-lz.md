# `SFPLZ` – Test Zero / Count Leading Zeros

**Category:** SFPU Comparison

**Syntax:** `SFPLZ VC, VD, Mod1`

**Operation (flag mode):** When `SFPLZ_MOD1_CC_NE0` (Mod1 bit 1) is set, `LaneFlags[lane] = (VC[lane] != 0)`. With `SFPLZ_MOD1_CC_COMP` (Mod1 bit 3), the flag is complemented: `LaneFlags[lane] = (VC[lane] == 0)`.

**Operation (int count):** `VD[lane] = CountLeadingZeros(VC[lane])`. When `SFPLZ_MOD1_NOSGN_MASK` (Mod1 bit 2) is set, the sign bit is masked before counting (sign-magnitude mode). Zero input yields 32 leading zeroes.

**Reserved Modifiers:** Mod1 bit 0 is reserved; setting it triggers NonContractualBehavior.

**Register Constraints:**
- VD: valid range `VD < 8 || VD == 16`; writes to invalid VD silently produce no result.
- LaneFlags written only when `VD < 8`.
- All operations gated by `LaneEnabled` per lane.

**Latency:** 1 cycle, IPC=1 (estimated)

**Backend:** Vector Unit (SFPU), simple sub-unit

**Configuration:** No special configuration required beyond standard SFPU setup.

**x86 Equivalent (CLZ):** `lzcnt` (scalar) / `VPLZCNTD` (AVX2+BMI2, 32-bit elements)

**Blackhole vs Wormhole:** Behavior is identical between Blackhole and Wormhole.

**Example:**
```asm
SFPLZ 1, 2, 0                                ; LReg[2] = count_leading_zeros(LReg[1]) per lane (default)
SFPLZ 1, 2, SFPLZ_MOD1_CC_NE0                ; Set LaneFlags where LReg[1] != 0
SFPLZ 1, 2, SFPLZ_MOD1_NOSGN_MASK            ; CLZ on sign-magnitude integers (sign bit masked)
SFPLZ 1, 2, SFPLZ_MOD1_CC_NE0 | SFPLZ_MOD1_CC_COMP ; Set LaneFlags where LReg[1] == 0
```
```markdown
# `SFPLZ` – Test Zero / Count Leading Zeros

**Category:** SFPU Comparison

**Syntax:** `SFPLZ VC, VD, Mod1`

**Operation (flag mode):** When `SFPLZ_MOD1_CC_NE0` (Mod1 bit 1) is set, `LaneFlags[lane] = (VC[lane] != 0)`. With `SFPLZ_MOD1_CC_COMP` (Mod1 bit 3), the flag is complemented: `LaneFlags[lane] = (VC[lane] == 0)`.

**Operation (int count):** `VD[lane] = CountLeadingZeros(VC[lane])`. When `SFPLZ_MOD1_NOSGN_MASK` (Mod1 bit 2) is set, the sign bit is masked before counting (sign-magnitude mode). Zero input yields 32 leading zeroes.

**Reserved Modifiers:** Mod1 bit 0 is reserved; setting it triggers NonContractualBehavior.

**Register Constraints:**
- VD: valid range `VD < 8 || VD == 16`; writes to invalid VD silently produce no result.
- LaneFlags written only when `VD < 8`.
- All operations gated by `LaneEnabled` per lane.

**Latency:** 1 cycle, IPC=1 (estimated)

**Backend:** Vector Unit (SFPU), simple sub-unit

**Configuration:** No special configuration required beyond standard SFPU setup.

**x86 Equivalent (CLZ):** `lzcnt` (scalar) / `VPLZCNTD` (AVX2+BMI2, 32-bit elements)

**Blackhole vs Wormhole:** Behavior is identical between Blackhole and Wormhole.

**Example:**
```asm
SFPLZ 1, 2, 0                                ; LReg[2] = count_leading_zeros(LReg[1]) per lane (default)
SFPLZ 1, 2, SFPLZ_MOD1_CC_NE0                ; Set LaneFlags where LReg[1] != 0
SFPLZ 1, 2, SFPLZ_MOD1_NOSGN_MASK            ; CLZ on sign-magnitude integers (sign bit masked)
SFPLZ 1, 2, SFPLZ_MOD1_CC_NE0 | SFPLZ_MOD1_CC_COMP ; Set LaneFlags where LReg[1] == 0
