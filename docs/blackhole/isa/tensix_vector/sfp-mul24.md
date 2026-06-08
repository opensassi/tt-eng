# `SFPMUL24` – 23-bit Integer Multiply

**Category:** SFPU Integer Arithmetic

**Backend:** SFPU MAD sub-unit

**Syntax:** `SFPMUL24 VA, VB, VC, VD, Mod1`

## Mod1 Modifier Flags

| Flag | Bit | Description |
|------|-----|-------------|
| `SFPMUL24_MOD1_UPPER` | 0 (0x1) | Select upper 23 bits of product |
| `SFPMUL24_MOD1_INDIRECT_VA` | 2 (0x4) | Override VA with `LReg[7]` low nibble per lane |
| `SFPMUL24_MOD1_INDIRECT_VD` | 3 (0x8) | Override VD with `LReg[7]` low nibble per lane (unless VD == 16) |

## Modes

| Mode | Operation |
|------|-----------|
| Mod1 bit 0 = 0 (non-UPPER) | `VD = (VA × VB) & 0x7FFFFF` (low 23 bits of 23b×23b product) |
| Mod1 bit 0 = 1 (UPPER) | `VD = ((VA & 0x7FFFFF) × (VB & 0x7FFFFF)) >> 23` (high 23 bits) |

**Latency:** 2 cycles, IPC=1

**x86 Equivalent:** `vpmuldq` (limited)

## Register Constraints

- **VD write target:** Writes to `LReg[vd]` only occur when `vd < 8` or `vd == 16`. Writes to `LReg[8–15]` (except `LReg[16]`) are silently dropped.
- **Read backdoor gating:** Operation is gated on `VD < 12` or `DISABLE_BACKDOOR_LOAD` being set. If `VD ≥ 12` and `DISABLE_BACKDOOR_LOAD` is clear, the instruction behaves as a no-op for that lane.
- **Indirect addressing:** When `Mod1` bit 2 (`INDIRECT_VA`) is set, `VA` is sourced from `LReg[7].u32 & 15` per lane. When `Mod1` bit 3 (`INDIRECT_VD`) is set and `VD != 16`, `VD` is sourced from `LReg[7].u32 & 15` per lane.
- **Lane gating:** Execution is per-lane and gated by `LaneEnabled`. Disabled lanes skip the operation.

## Examples

```asm
; 23-bit integer multiply: LReg[2] = (LReg[0] × LReg[1]) & 0x7FFFFF
SFPMUL24 0, 1, 2, 0, 0          ; Mod1=0 (non-UPPER)

; Fixed-point multiply: LReg[2] = (LReg[0] & 0x7FFFFF) × (LReg[1] & 0x7FFFFF) >> 23
SFPMUL24 0, 1, 2, 0, 1          ; Mod1=1 (UPPER)

; Indirect VA: VA sourced from LReg[7] low nibble per lane
SFPMUL24 0, 1, 2, 0, 4          ; Mod1=4 (SFPMUL24_MOD1_INDIRECT_VA)
