# `SFPLUTFP32` – FP32 Lookup Table

**Category:** SFPU Special Function

**Syntax:** `SFPLUTFP32 VD, Mod1`

**Backend execution unit:** Vector Unit (SFPU), MAD sub-unit

Operating lanewise, performs one of the FP32 multiply-then-add variants from the tables below. After the computation, the sign bit of the result can optionally be replaced with the original sign bit of `LReg[3]` (via `SFPLUTFP32_MOD1_SGN_RETAIN`).

## Modes

### FP32_3ENTRY_TABLE (`Mod1=0`)

Piecewise linear with 3 FP32 segments:

| Input Range | Computation |
|---|---|
| `0.0 ≤ Abs(LReg[3]) < 1.0` | `VD = LReg[0] × Abs(LReg[3]) + LReg[4]` |
| `1.0 ≤ Abs(LReg[3]) < 2.0` | `VD = LReg[1] × Abs(LReg[3]) + LReg[5]` |
| `2.0 ≤ Abs(LReg[3])` | `VD = LReg[2] × Abs(LReg[3]) + LReg[6]` |

### FP16_3ENTRY_TABLE (`Mod1=10`)

Due to a hardware bug, this mode writes to `LReg[LReg[7] & 15]` rather than to `LReg[VD]`. Software should ensure the low four bits of `LReg[7]` contain the intended destination.

| Input Range | Computation |
|---|---|
| `0.0 ≤ Abs(LReg[3]) < 1.0` | `LReg[LReg[7] & 15] = Lut16ToFp32(LReg[0] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[0])` |
| `1.0 ≤ Abs(LReg[3]) < 2.0` | `LReg[LReg[7] & 15] = Lut16ToFp32(LReg[1] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[1])` |
| `2.0 ≤ Abs(LReg[3])` | `LReg[LReg[7] & 15] = Lut16ToFp32(LReg[2] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[2])` |

### FP16_6ENTRY_TABLE1 (`Mod1=2`)

6-entry FP16 table with split at 3.0:

| Input Range | Computation |
|---|---|
| `0.0 ≤ Abs(LReg[3]) < 0.5` | `VD = Lut16ToFp32(LReg[0]) × Abs(LReg[3]) + Lut16ToFp32(LReg[4])` |
| `0.5 ≤ Abs(LReg[3]) < 1.0` | `VD = Lut16ToFp32(LReg[0] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[4] >> 16)` |
| `1.0 ≤ Abs(LReg[3]) < 1.5` | `VD = Lut16ToFp32(LReg[1]) × Abs(LReg[3]) + Lut16ToFp32(LReg[5])` |
| `1.5 ≤ Abs(LReg[3]) < 2.0` | `VD = Lut16ToFp32(LReg[1] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[5] >> 16)` |
| `2.0 ≤ Abs(LReg[3]) < 3.0` | `VD = Lut16ToFp32(LReg[2]) × Abs(LReg[3]) + Lut16ToFp32(LReg[6])` |
| `3.0 ≤ Abs(LReg[3])` | `VD = Lut16ToFp32(LReg[2] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[6] >> 16)` |

### FP16_6ENTRY_TABLE2 (`Mod1=3`)

Identical to FP16_6ENTRY_TABLE1 except the final non-linear split is at 4.0 instead of 3.0:

| Input Range | Computation |
|---|---|
| `0.0 ≤ Abs(LReg[3]) < 0.5` | `VD = Lut16ToFp32(LReg[0]) × Abs(LReg[3]) + Lut16ToFp32(LReg[4])` |
| `0.5 ≤ Abs(LReg[3]) < 1.0` | `VD = Lut16ToFp32(LReg[0] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[4] >> 16)` |
| `1.0 ≤ Abs(LReg[3]) < 1.5` | `VD = Lut16ToFp32(LReg[1]) × Abs(LReg[3]) + Lut16ToFp32(LReg[5])` |
| `1.5 ≤ Abs(LReg[3]) < 2.0` | `VD = Lut16ToFp32(LReg[1] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[5] >> 16)` |
| `2.0 ≤ Abs(LReg[3]) < 4.0` | `VD = Lut16ToFp32(LReg[2]) × Abs(LReg[3]) + Lut16ToFp32(LReg[6])` |
| `4.0 ≤ Abs(LReg[3])` | `VD = Lut16ToFp32(LReg[2] >> 16) × Abs(LReg[3]) + Lut16ToFp32(LReg[6] >> 16)` |

## Mod1 Constants

| Constant | Value | Description |
|---|---|---|
| `SFPLUTFP32_MOD1_FP32_3ENTRY_TABLE` | 0 | 3-segment FP32 piecewise linear |
| `SFPLUTFP32_MOD1_FP16_6ENTRY_TABLE1` | 2 | 6-entry FP16, split at 3.0 |
| `SFPLUTFP32_MOD1_FP16_6ENTRY_TABLE2` | 3 | 6-entry FP16, split at 4.0 |
| `SFPLUTFP32_MOD1_SGN_RETAIN` | 4 | Preserve sign of `LReg[3]` in result |
| `SFPLUTFP32_MOD1_INDIRECT_VD` | 8 | Destination from `LReg[7] & 15` |
| `SFPLUTFP32_MOD1_FP16_3ENTRY_TABLE` | 10 | 3-entry FP16 (buggy writes to `LReg[LReg[7] & 15]`) |

Note: `SFPLUTFP32_MOD1_FP16_3ENTRY_TABLE` (10) overlaps with `SFPLUTFP32_MOD1_INDIRECT_VD` (8). Mode constants can be OR'd with `SFPLUTFP32_MOD1_SGN_RETAIN` to preserve the sign.

## Register Constraints

- **Write guard:** Writes only proceed when `VD < 12 || LaneConfig[Lane].DISABLE_BACKDOOR_LOAD`.
- **Lane enable:** Writes are gated by `LaneEnabled`.
- **VD write range:** The final destination register must satisfy `vd < 8 || vd == 16` for the write to occur.
- **INDIRECT_VD:** When `Mod1 & SFPLUTFP32_MOD1_INDIRECT_VD` is set and `VD != 16`, the destination is `vd = LReg[7].u32 & 15`. Software must pre-load `LReg[7]` with the intended destination in its low four bits. This is also implicitly active in FP16_3ENTRY_TABLE mode (`Mod1=10`).

## Scheduling

If `SFPLUTFP32` is used, software must ensure that on the next cycle, the Vector Unit (SFPU) does not execute an instruction which reads from any location written to by the `SFPLUTFP32`. An `SFPNOP` instruction can be inserted to ensure this.

## Known Bugs & Errata

- **FP16_3ENTRY_TABLE (`Mod1=10`) writes to wrong destination:** Due to a hardware bug, this mode writes to `LReg[LReg[7] & 15]` rather than to `LReg[VD]`. Workaround: ensure the low four bits of `LReg[7]` contain the intended VD value. This mode overlaps with `SFPLUTFP32_MOD1_INDIRECT_VD` (bit 3), which is the likely cause.

## Lut16ToFp32 Conversion

`Lut16ToFp32` converts a 16-bit unsigned value to IEEE754 FP32. Some bit patterns are interpreted differently than standard IEEE 754 FP16.

| Sign | Exp (5b) | Mant (10b) | IEEE 754 FP16 | `SFPLUTFP32`'s `Lut16ToFp32` |
|---|---|---|---|---|
| 0 | 31 | Non-zero | +NaN | +0 |
| 0 | 31 | 0 | +Infinity | +0 |
| 0 | 1–30 | Any | (same) | (same) |
| 0 | 0 | Non-zero | Subnormal | Normalized |
| 0 | 0 | 0 | +0 | Normalized (→ +2⁻¹⁵) |
| 1 | 0 | 0 | −0 | Normalized (→ −2⁻¹⁵) |
| 1 | 0 | Non-zero | −Subnormal | Normalized |
| 1 | 1–30 | Any | (same) | (same) |
| 1 | 31 | 0 | −Infinity | −0 |
| 1 | 31 | Non-zero | −NaN | −0 |

Implementation:

```c
float Lut16ToFp32(uint16_t x) {
    uint32_t Sign = x >> 15;
    uint32_t Exp  = (x >> 10) & 0x1f;
    uint32_t Man  = x & 0x3ff;
    return std::bit_cast<float>((Sign << 31) | ((Exp == 0x1f ? 0 : 112 + Exp) << 23) | (Man << 13));
}
