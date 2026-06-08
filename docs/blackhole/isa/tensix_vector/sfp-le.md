# `SFPLE` – Less or Equal (FP32 / Sign-Mag Integer)

**Category:** SFPU Comparison

**Syntax:** `SFPLE VC, VD, Mod1    ; VB=VD (destructive, VD is both source and destination)`

**Operation (FP32):** `if Mod1 & 1, LaneFlags[lane] = (VD[lane] <= VC[lane])`. Uses total order: -NaN < -Inf < ... < -0 < +0 < ... < +Inf < +NaN.

**Operation (sign-mag int):** `if Mod1 & 8 and VD ∈ {0..7, 16}: VD[lane] = (VD <= VC) ? -1 : 0`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vcmpps` with LE predicate

**Backend:** SFPU simple sub-unit.

**Note:** Blackhole-only instruction. Not available on Wormhole.

**Mod1 constants:** SET_CC=1, MUTATE_STACK=2, MUTATE_OR=4, SET_VD=8

**Flag Stack Mutation:** With Mod1 & 2 and flag stack non-empty: if Mod1 & 4, result is ORed into FlagStack.Top().LaneFlags; otherwise ANDed.

**Register Constraints:**
- VD write targets: LReg[0..7, 16] only.
- VD read (source): requires VD < 12 or `LaneConfig.DISABLE_BACKDOOR_LOAD`.

**Operation gated by LaneEnabled per lane.**

**Example:**
```asm
SFPLE 1, 2, 9  ; SET_CC=1 | SET_VD=8 → LaneFlags |= (LReg[2] <= LReg[1]); LReg[2] = -1/0
