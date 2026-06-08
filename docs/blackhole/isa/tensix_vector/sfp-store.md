# `SFPSTORE` – Store LReg → Dst

**Category:** SFPU Data Movement

**Backend:** Vector Unit (SFPU)

**Syntax:** `SFPSTORE VD, Mod0, AddrMod, Imm10`

**Operation:** For each of 32 lanes: read `LReg[VD][Lane]`, apply `Mod0`-selected data type conversion, compute Dst address — `Row = ((Addr & ~3) + Lane/8)`, `Column = ((Lane & 7)*2 + offset)` where `offset = 1` if `(Addr & 2) || DEST_WR_COL_EXCHANGE` else `0` — then conditionally write to `Dst`. Writes are gated by `BLOCK_DEST_WR_FROM_SFPU` and `LaneEnabled` (except in `MOD0_FMT_INT32_ALL` mode).

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vmovaps`

Stores LReg vector register to Dst (for subsequent pack to L1 or matrix reuse). To bridge the gap between LReg and Dst data types, data type conversions are supported as part of the instruction, though software might still want a preceding `SFPSTOCHRND` or `SFPCAST` instruction to achieve a richer set of conversions.

## Data Type Conversions

The `Mod0` field selects one of 16 conversion modes:

| Mode | Expected LReg Data Type | → | Resultant Dst Data Type |
|------|------------------------|---|------------------------|
| `MOD0_FMT_FP16` | FP32 (not containing NaN) | → | FP16 (†) |
| `MOD0_FMT_BF16` | FP32 (not containing NaN) | → | BF16 (†) |
| `MOD0_FMT_FP32` | FP32 or sign-magnitude integer | → | FP32 or Integer "32" |
| `MOD0_FMT_INT32` | FP32 or sign-magnitude integer | → | FP32 or Integer "32" |
| `MOD0_FMT_INT32_ALL` (‡) | FP32 or sign-magnitude integer | → | FP32 or Integer "32" |
| `MOD0_FMT_INT32_SM` | Two's complement integer (not containing -2³¹) | → | Integer "32" |
| `MOD0_FMT_INT8` | Sign-magnitude integer in range ±1023 | → | Integer "8" |
| `MOD0_FMT_INT8_COMP` | Two's complement integer in range ±1023 | → | Integer "8" |
| `MOD0_FMT_LO16_ONLY` | Unsigned integer (low 16 bits) | → | Integer "16" (opaque) |
| `MOD0_FMT_HI16_ONLY` | Unsigned integer (high 16 bits) | → | Integer "16" (opaque) |
| `MOD0_FMT_INT16` | Sign-magnitude integer in range ±32767 | → | Integer "16" |
| `MOD0_FMT_UINT16` | Unsigned integer (low 16 bits) | → | Integer "16" (opaque) |
| `MOD0_FMT_LO16` | Unsigned integer (rotated left by 16 bits) | → | Opaque 32 bits |
| `MOD0_FMT_HI16` | Unsigned integer | → | Opaque 32 bits |
| `MOD0_FMT_ZERO` | Any | → | Zero |
| `MOD0_FMT_SRCB` | Resolves per config (see below) | → | FP16/BF16/FP32 |

(†) Denormals flushed to signed zero; mantissa truncated toward zero. FP16: large magnitudes and NaN → infinity. BF16: mantissa truncation may turn some NaNs into infinity.

(‡) Alters addressing scheme and ignores `LaneEnabled`; see functional model.

The `MOD0_FMT_SRCB` mode resolves per `ConfigState`: if `ALU_ACC_CTRL_SFPU_Fp32_enabled` then `MOD0_FMT_FP32`; otherwise based on `ALU_FORMAT_SPEC_REG_SrcB` — BF16 for FP32/TF32/BF16/BFP8/BFP4/BFP2/INT32/INT16 formats, otherwise FP16.

## Cross-Lane Data Movement Pattern

The pattern is the exact inverse of [`SFPLOAD`](SFPLOAD.md).

## Functional Model

```c
uint1_t StateID = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID;
auto& ConfigState = Config[StateID];

if (Mod0 == MOD0_FMT_SRCB) {
  if (ConfigState.ALU_ACC_CTRL_SFPU_Fp32_enabled) {
    Mod0 = MOD0_FMT_FP32;
  } else {
    uint4_t SrcBFmt = ConfigState.ALU_FORMAT_SPEC_REG_SrcB_override
      ? ConfigState.ALU_FORMAT_SPEC_REG_SrcB_val
      : ConfigState.ALU_FORMAT_SPEC_REG1_SrcB;
    if (SrcBFmt in {FP32, TF32, BF16, BFP8, BFP4, BFP2, INT32, INT16}) {
      Mod0 = MOD0_FMT_BF16;
    } else {
      Mod0 = MOD0_FMT_FP16;
    }
  }
}

uint10_t Addr = Imm10 + ThreadConfig[CurrentThread].DEST_TARGET_REG_CFG_MATH_Offset;
if (Mod0 == MOD0_FMT_INT32_ALL) {
  Addr += (RWCs[CurrentThread].Dst + ConfigState.DEST_REGW_BASE_Base) & 3;
} else {
  Addr += RWCs[CurrentThread].Dst + ConfigState.DEST_REGW_BASE_Base;
}

for (unsigned Lane = 0; Lane < 32; ++Lane) {
  if (LaneConfig[Lane].BLOCK_DEST_WR_FROM_SFPU) continue;
  if (VD < 12 || LaneConfig[Lane].DISABLE_BACKDOOR_LOAD) {
    if (LaneEnabled[Lane] || Mod0 == MOD0_FMT_INT32_ALL) {
      uint32_t Datum = LReg[VD][Lane].u32;
      uint10_t Row = (Addr & ~3) + (Lane / 8);
      uint4_t Column = (Lane & 7) * 2;
      if ((Addr & 2) || LaneConfig[Lane & 7].DEST_WR_COL_EXCHANGE) {
        Column += 1;
      }
      switch (Mod0) {
      case MOD0_FMT_FP16:      Dst16b[Row][Column] = DstEncodeFP16(ToFP16(Datum)); break;
      case MOD0_FMT_BF16:      Dst16b[Row][Column] = DstEncodeBF16(ToBF16(Datum)); break;
      case MOD0_FMT_FP32:      Dst32b[Row][Column] = DstEncodeFP32(Datum); break;
      case MOD0_FMT_INT32:     Dst32b[Row][Column] = DstEncodeFP32(Datum); break;
      case MOD0_FMT_INT32_ALL: Dst32b[Row][Column] = DstEncodeFP32(Datum); break;
      case MOD0_FMT_INT32_SM:  Dst32b[Row][Column] = DstEncodeFP32(ToSignMag(Datum)); break;
      case MOD0_FMT_INT8:      Dst16b[Row][Column] = DstEncodeFP16(SignMag11ToFP16(Datum)); break;
      case MOD0_FMT_INT8_COMP: Dst16b[Row][Column] = DstEncodeFP16(SignMag11ToFP16(ToSignMag(Datum))); break;
      case MOD0_FMT_LO16_ONLY: Dst16b[Row][Column] = Datum & 0xffff; break;
      case MOD0_FMT_HI16_ONLY: Dst16b[Row][Column] = Datum >> 16; break;
      case MOD0_FMT_INT16:     Dst16b[Row][Column] = ((Datum >> 31) << 15) | (Datum & 0x7fff); break;
      case MOD0_FMT_UINT16:    Dst16b[Row][Column] = Datum & 0xffff; break;
      case MOD0_FMT_LO16:      Dst32b[Row][Column] = (Datum << 16) | (Datum >> 16); break;
      case MOD0_FMT_HI16:      Dst32b[Row][Column] = Datum; break;
      case MOD0_FMT_ZERO:      Dst16b[Row][Column] = 0; break;
      }
    }
  }
}

ApplyPartialAddrMod(AddrMod);
