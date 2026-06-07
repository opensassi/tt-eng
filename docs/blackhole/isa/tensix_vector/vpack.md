# `vpack` – Vector Pack (SFPU / Packer)

**Category:** Data Format Conversion

**SFPU mnemonic:** `SFPSTOCHRND` (stochastic rounding / pack) + Packer hardware

**Syntax:**
```c
TT_SFP_STOCH_RND(RoundingMode, Imm5/VB, VC, VD, Mod1)
```

**Operation:** Convert and pack wider data types into narrower formats. Packer hardware in the Tensix coprocessor handles data movement from Dst register to L1 with format conversion.

Supported conversions:

| Mode | Conversion | x86 EQ | Saturation |
|------|-----------|--------|------------|
| `SFPSTOCHRND_FloatFloat` | FP32 → BF16/TF32 | `vcvtneps2bf16` | None (rounding) |
| `SFPSTOCHRND_FloatInt` | FP32 → INT8/INT16 | — | Clamp to ±127/±32767 |
| `SFPSTOCHRND_IntInt` (signed) | INT32 → INT8 | `vpackssdw` / `vpacksswb` | Clamp to ±127 |
| `SFPSTOCHRND_IntInt` (unsigned) | INT32 → UINT8 | `vpackusdw` / `vpackuswb` | Clamp to 0..255 |

**Unsigned pack detail:** `SFPSTOCHRND_MOD1_INT32_TO_UINT8` shifts the magnitude right, rounds stochastically (or to nearest/zero), takes absolute value, and clamps to 0..255. The result is a sign-magnitude integer with sign=0, which can be interpreted as unsigned 8-bit.

**Rounding modes:**
- `SFPSTOCHRND_RND_NEAREST` — Round to nearest, ties away from zero
- `SFPSTOCHRND_RND_STOCH` — Stochastic rounding (unbiased, but has known hardware bug favoring magnitude increase)
- `SFPSTOCHRND_RND_ZERO` — Round toward zero (new in Blackhole; buggy for shifts > 22 bits)

**Latency:** 1 cycle (SFPU part) + packer latency

**IPC:** 1

**Example:**
```asm
; Convert 4 LReg values from INT32 → UINT8 with stochastic rounding
SFPSTOCHRND SFPSTOCHRND_RND_STOCH, 0, 1, 2, SFPSTOCHRND_MOD1_INT32_TO_UINT8
; LReg[2] = Clamp(Abs(LReg[1]) >> 0, 0..255), stochastically rounded
```

**Notes:**
- Stochastic rounding can be used for unbiased down-conversion. Due to a hardware bug, stochastic rounding has a slight bias towards increasing magnitude.
- The Packer hardware handles output address generation, edge masking, downsampling, and exponent thresholding.
- For non-power-of-two scaling, use `SFPMUL24` to scale before `SFPSTOCHRND`.
- When `UseImm5` is false, set `VB == VC` to work around a false dependency bug.
