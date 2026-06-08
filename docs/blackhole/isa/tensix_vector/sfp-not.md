# `SFPNOT` – Bitwise NOT

**Category:** SFPU Bitwise Logical

**Syntax:** `SFPNOT VC, VD`

**Modifiers:** `TT_SFPNOT(0 /* Mod0, must be 0 */, VC, VD, 0 /* Mod1, must be 0 */)`. Both modifier fields are reserved and must be zero. Non-zero values cause NonContractualBehavior.

**Operation:** `for lane in 0..31: VD[lane] = ~VC[lane]`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vpternlog` (with constant all-ones)

**Register Constraints:**
- `VD` must satisfy `VD < 8 || VD == 16`. Writes to LReg indices outside this range (8–15, 17–31) are silently dropped.
- The operation is per-lane gated by `LaneEnabled`. When `LaneEnabled` is false for a given lane, the write to that lane is suppressed. LaneConfig controls which lanes are enabled.

**Backend:**
- Executes on the SFPU simple sub-unit, the lowest-latency SFPU sub-unit. Can be parallelized with MAD/round sub-unit instructions via SFPLOADMACRO.

**Blackhole/Wormhole:** Identical behavior. No BH-specific changes.

**Example:**
```asm
SFPNOT 0, 1      ; LReg[1] = ~LReg[0]  (bitwise NOT all lanes)
