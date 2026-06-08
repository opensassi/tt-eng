# `SFPMOV` – Register Copy (Mode)

**Category:** SFPU Data Movement

**Syntax:** `SFPMOV 0, VC, VD, Mod1` (copy mode)

**Operation:** The full operation is gated by three preconditions:
1. **Global gate:** `VD < 12 || LaneConfig.DISABLE_BACKDOOR_LOAD` — if false, the entire operation is silently a no-op.
2. **Per-lane gate:** `LaneEnabled || ALL_LANES_ENABLED` — if false for a given lane, that lane is not written.
3. **Write gate:** `VD < 8 || VD == 16` — if false, the write to the destination register is suppressed.
When all three gates pass: `for lane in 0..31: VD[lane] = VC[lane]`

**Latency:** 1 cycle, IPC=1

**Backend:** simple sub-unit

**Register constraint:** VD must be < 8 or == 16 for the write to take effect. Additionally, VD must be < 12 (or `LaneConfig.DISABLE_BACKDOOR_LOAD` must be set) for the operation to have any effect at all.

**ALL_LANES_ENABLED mode:** Mod1 bit 1 (SFPMOV_MOD1_ALL_LANES_ENABLED=2) bypasses the lane-enable mask, forcing all lanes to be written. By default (Mod1=0), only lanes where `LaneEnabled` is true are written.

**Reserved bit:** Mod1 bit 2 is reserved — NonContractualBehavior (silently cleared on current silicon)

**LaneConfig.DISABLE_BACKDOOR_LOAD:** When this LaneConfig bit is 0 and VD >= 12, the entire SFPMOV operation is silently a no-op. This gate is checked before any per-lane processing.

**x86 Equivalent:** `vmovaps`

**Cross-reference:** Other SFPMOV modes: negate (sfp-neg.md), config read (sfp-config-read.md), PRNG (sfp-prng.md)

**Notes:**
- SFPMOV copy is a raw bit-preserving u32 move; no type interpretation occurs.
- Scheduling is handled by the simple sub-unit; no interlock with other SFPU sub-units.
- The three-level gating chain (global gate → per-lane gate → write gate) applies in all cases.
- Behavior is identical on Blackhole and Wormhole.

**Example:**
```asm
; MOD_COPY = 0
SFPMOV 0, 2, 3, 0   ; LReg[3] = LReg[2]  (register copy, SFPMOV with Mod1=0)
