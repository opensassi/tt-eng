# `vmin` – Vector Minimum (SFPU)

**Category:** SFPU Vector Arithmetic

**Real instruction:** `SFPSWAP` — there is no separate `vmin` instruction. This describes `SFPSWAP` with `Mod1 = SFPSWAP_MOD1_VEC_MIN_MAX`.

**SFPU mnemonic:** `SFPSWAP`

**Syntax (C++ intrinsic):** `TT_SFPSWAP(0, /* u4 */ VC, /* u4 */ VD, /* u4 */ Mod1)`

**Assembly syntax:** `SFPSWAP 0, VC, VD, Mod1`

**Operation (Mod1 = SFPSWAP_MOD1_VEC_MIN_MAX, the min+max mode):** `for lane in 0..31: { VD[lane] = Min(VC[lane], VD[lane]); VC[lane] = Max(VC[lane], VD[lane]) }`

Simultaneously computes min and max of two vector registers. Min is in VD, max overwrites VC.

**All Mod1 modes:**

| Mod1 | Constant | Behavior |
|------|----------|----------|
| 0 | `SFPSWAP_MOD1_SWAP` | Unconditional swap of VD and VC |
| 1 | `SFPSWAP_MOD1_VEC_MIN_MAX` | All lanes: VD = min, VC = max |
| 2 | `SFPSWAP_MOD1_SUBVEC_MIN01_MAX23` | Lanes 0-15: VD=min,VC=max; lanes 16-31: VD=max,VC=min |
| 3 | `SFPSWAP_MOD1_SUBVEC_MIN02_MAX13` | Lane pattern 0x00ff00ff |
| 4 | `SFPSWAP_MOD1_SUBVEC_MIN03_MAX12` | Lanes 0-7,24-31: VD=min,VC=max; lanes 8-23: VD=max,VC=min |
| 5 | `SFPSWAP_MOD1_SUBVEC_MIN0_MAX123` | Lanes 0-7: VD=min,VC=max; lanes 8-31: VD=max,VC=min |
| 6 | `SFPSWAP_MOD1_SUBVEC_MIN1_MAX023` | Lane pattern 0x0000ff00 |
| 7 | `SFPSWAP_MOD1_SUBVEC_MIN2_MAX013` | Lane pattern 0x00ff0000 |
| 8 | `SFPSWAP_MOD1_SUBVEC_MIN3_MAX012` | Lane pattern 0xff000000 |
| 9 | (no named constant) | All lanes: VD = max, VC = min |
| others | — | Non-contractual: all lanes VD = max, VC = min (current silicon, not architecturally guaranteed) |

**x86 Equivalent:** `vminps` / `vpminud` (AVX2)

**Latency:** 2 cycles

**IPC:** ≤ 1 (shared SFPU resource)

**Example:**
```asm
; Min+max: LReg[0] = Min(LReg[0], LReg[1]) AND LReg[1] = Max(LReg[0], LReg[1])
SFPSWAP 0, 0, 1, SFPSWAP_MOD1_VEC_MIN_MAX
; After: LReg[0] = min(old_LReg[0], old_LReg[1]), LReg[1] = max(old_LReg[0], old_LReg[1])
