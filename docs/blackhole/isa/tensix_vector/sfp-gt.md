# `SFPGT` – Greater Than (FP32 / Sign-Mag Integer)

**Category:** SFPU Comparison

**Syntax:** `SFPGT VC, VD, Mod1`

**Backend:** SFPU simple sub-unit

New in Blackhole. Inverse: [`SFPLE`](SFPLE.md).

**Operation (FP32):** `for lane in 0..31: LaneFlags[lane] = (VD[lane] > VC[lane])`

NaN ordering: -NaN < -Inf < ... < -0 < +0 < ... < +Inf < +NaN.

**Operation (sign-mag int):** `VD[lane] = VD > VC ? -1 (0xFFFFFFFF/0x80000001 in sign-mag) : +0`. Treats -0 < +0.

Denormals are compared by their bit-level sign-magnitude representation; no flush to zero.

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vcmpps` with GT predicate

**Register Constraints:**
- SET_VD write requires `VD < 8 || VD == 16`
- SET_CC write requires `VD < 12 || LaneConfig.DISABLE_BACKDOOR_LOAD`
- All lanes gated by `LaneEnabled`

**Example:**
```asm
SFPGT 1, 2, 1       ; Set LaneFlags where LReg[2] > LReg[1]; used with SFPENCC for predication
