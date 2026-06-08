# `SFPLOAD` – Load Dst → LReg

**Category:** SFPU Data Movement

**Backend:** Vector Unit (SFPU), load sub-unit

**Syntax:** `SFPLOAD VD, Mod0, AddrMod, Imm10`

**Operation:** Loads up to 32 datums from the even or odd columns of four consecutive rows of the Dst register file into an LReg vector register, applying a per-lane data-type conversion selected by `Mod0`. The Dst address is formed from `Imm10 + DEST_TARGET_REG_CFG_MATH_Offset + RWCs.Dst + DEST_REGW_BASE` (for `MOD0_FMT_INT32_ALL`, only the low 2 bits of the RWC+Dst base are added).

**Mod0 constants:**

| Constant | Value | Description |
|----------|-------|-------------|
| `MOD0_FMT_SRCB` | 0 | Resolved via ALU_FORMAT_SPEC_REG |
| `MOD0_FMT_FP16` | 1 | FP16 → FP32 |
| `MOD0_FMT_BF16` | 2 | BF16 → FP32 |
| `MOD0_FMT_FP32` | 3 | FP32 pass-through |
| `MOD0_FMT_INT32` | 4 | Integer "32" pass-through |
| `MOD0_FMT_INT8` | 5 | Sign-magnitude INT8 → sign-magnitude INT32 |
| `MOD0_FMT_UINT16` | 6 | UINT16 zero-extend to 32 |
| `MOD0_FMT_HI16` | 7 | Write high 16 bits, zero low 16 |
| `MOD0_FMT_INT16` | 8 | Sign-magnitude INT16 → sign-magnitude INT32 |
| `MOD0_FMT_LO16` | 9 | UINT16 zero-extend to 32 |
| `MOD0_FMT_INT32_ALL` | 10 | Same as INT32; overrides LaneEnabled; BH addressing differs |
| `MOD0_FMT_ZERO` | 11 | Force to +0 (negative zero → positive zero) |
| `MOD0_FMT_INT32_SM` | 12 | Sign-magnitude → two's complement (deprecated on BH) |
| `MOD0_FMT_INT8_COMP` | 13 | INT8 → two's complement (deprecated on BH) |
| `MOD0_FMT_LO16_ONLY` | 14 | Write low 16 bits, preserve high 16 |
| `MOD0_FMT_HI16_ONLY` | 15 | Write high 16 bits, preserve low 16 |

**Data-type conversion table:**

| Mod0 | Dst data type | → | LReg data type |
|------|---------------|---|----------------|
| `MOD0_FMT_FP16` | FP16 (configurable infinity handling) | → | FP32 |
| `MOD0_FMT_BF16` | BF16 | → | FP32 |
| `MOD0_FMT_FP32` | FP32 or Integer "32" | → | FP32 or sign-magnitude integer |
| `MOD0_FMT_INT32` | FP32 or Integer "32" | → | FP32 or sign-magnitude integer |
| `MOD0_FMT_INT32_ALL` | FP32 or Integer "32" | → | FP32 or sign-magnitude integer |
| `MOD0_FMT_INT32_SM` | Integer "32" | → | Two's complement integer |
| `MOD0_FMT_INT8` | Integer "8" | → | Sign-magnitude integer |
| `MOD0_FMT_INT8_COMP` | Integer "8" | → | Two's complement integer |
| `MOD0_FMT_LO16_ONLY` | Integer "16" (opaque 16 bits) | → | Unsigned int (low 16, preserve high 16) |
| `MOD0_FMT_HI16_ONLY` | Integer "16" (opaque 16 bits) | → | Unsigned int (high 16, preserve low 16) |
| `MOD0_FMT_INT16` | Integer "16" | → | Sign-magnitude integer |
| `MOD0_FMT_UINT16` | Integer "16" (opaque 16 bits) | → | Unsigned int (zero-extend) |
| `MOD0_FMT_LO16` | Integer "16" (opaque 16 bits) | → | Unsigned int (zero-extend) |
| `MOD0_FMT_HI16` | Integer "16" (opaque 16 bits) | → | Unsigned int (high 16, zero low 16) |
| `MOD0_FMT_ZERO` | any | → | +0 (negative zero → positive zero) |

The `MOD0_FMT_SRCB` mode resolves to `MOD0_FMT_FP32` when `ALU_ACC_CTRL_SFPU_Fp32_enabled` is set; otherwise resolves to `MOD0_FMT_BF16` or `MOD0_FMT_FP16` based on `ALU_FORMAT_SPEC_REG_SrcB`.

**Register Constraints:**
- Only `LReg[0..7]` are valid destinations (`VD < 8`).
- `LaneEnabled` gates the write for all modes except `MOD0_FMT_INT32_ALL` (which ignores `LaneEnabled`).
- `BLOCK_SFPU_RD_FROM_DEST`: when set for a lane, the read from Dst is suppressed entirely.
- When `VD < 4` and both `LaneConfig.ENABLE_DEST_INDEX` and `LaneConfig.CAPTURE_DEFAULT_DEST_INDEX` are set, the lane's `(Row, Column)` is written to `LReg[VD+4]`.
- `LaneConfig.DEST_RD_COL_EXCHANGE` swaps even ↔ odd column selection for the 8-lane group.

**IEEE754 & Edge Cases:**
- **FP16A infinity remapping:** When `LaneConfig.ENABLE_FP16A_INF` is set and the FP16 value has `Exp == 0x1f` and `Man == 0x3ff`, the value is remapped to IEEE754 infinity (`Exp = 255, Man = 0`).
- **Denormals:** SFPLOAD passes denormals through (may produce a different denormal). Subsequent arithmetic operations flush denormals to zero.
- **`MOD0_FMT_ZERO`:** Replaces datum with `0` unconditionally; negative zero becomes positive zero.

**Configuration Requirements:**
- `ThreadConfig.CFG_STATE_ID` routes the active `ConfigState`.
- `ConfigState.DEST_REGW_BASE` supplies the Dst address base.
- `ThreadConfig.DEST_TARGET_REG_CFG_MATH_Offset` provides per-thread row offset.
- `ConfigState.ALU_ACC_CTRL` and `ALU_FORMAT_SPEC_REG` resolve `MOD0_FMT_SRCB`.
- `LaneConfig.BLOCK_SFPU_RD_FROM_DEST`: per-lane read suppression.
- `LaneConfig.ENABLE_FP16A_INF`: FP16 infinity remapping enable.
- `LaneConfig.DEST_RD_COL_EXCHANGE`: column swap per 8-lane group.
- `LaneConfig.ENABLE_DEST_INDEX` + `CAPTURE_DEFAULT_DEST_INDEX`: index capture enable.

**Blackhole Differences:**
- `MOD0_FMT_INT32_ALL`: Overhauled addressing mode (only `(RWCs.Dst + DEST_REGW_BASE) & 3` added, keeping address aligned to 4-row groups).
- `MOD0_FMT_INT8`: Range expanded from ±127 to ±255.
- `MOD0_FMT_INT8_COMP`: Deprecated — no longer performs data type conversion.
- `MOD0_FMT_INT32_SM`: Deprecated — no longer performs data type conversion.

**Errata:**
- BH: `MOD0_FMT_SRCB` resolution path via `ALU_FORMAT_SPEC_REG_SrcB` is not fully characterized; use explicit `Mod0` values on Blackhole.

**Scheduling Hazard:**
- After a Matrix Unit write to Dst, insert ≥3 unrelated Tensix instructions before SFPLOAD reads the same Dst region. Alternatively, use `STALLWAIT` with block bit B8 and condition code C7.

**Performance:** Latency estimated; verify experimentally. The instruction executes on the load sub-unit of the Vector Unit (SFPU).

**Example:**
```asm
SFPLOAD 1, 1, 0, 0   ; LReg[1] = Dst[0:3, even rows]  (VD=1, MOD0_FMT_FP16, AddrMod=0, Imm10=0)
SFPLOAD 2, 1, 0, 8   ; LReg[2] = Dst[8:11, even rows] (VD=2, MOD0_FMT_FP16, AddrMod=0, Imm10=8)
