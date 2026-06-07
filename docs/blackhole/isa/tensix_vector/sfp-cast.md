# `SFPCAST` – Vector Type Conversion

**Category:** SFPU Data Type Conversion

**Backend execution unit:** Vector Unit (SFPU), simple sub-unit (all modes).

## Modes

| Mode | Operation | Latency |
|------|-----------|:---:|
| IntFloat | `VD = SignMag32ToFp32(VC)` (sign-mag integer → FP32) | 1 cyc |
| IntInt (s→i) | `VD = SignMag32ToInt32(VC)` or `VD = -2^31` when -0 | 1 cyc |
| IntInt (i→s) | `VD = Int32ToSignMag32(VC)` or `VD = -0` when -2^31 | 1 cyc |
| IntAbs | `VD = Abs(VC, signed int)` | 1 cyc |

All IPC=1.

## Mod1 Constants

| Constant | Value | Mode |
|----------|:-----:|------|
| `SFPCAST_MOD1_SM32_TO_FP32_RNE` | 0 | IntFloat, round to nearest, ties to even |
| `SFPCAST_MOD1_SM32_TO_FP32_RNS` | 1 | IntFloat, stochastic rounding (7 PRNG bits) |
| `SFPCAST_MOD1_INT32_ABS` | 2 | IntAbs |
| `SFPCAST_MOD1_INT32_SM32` | 3 | IntInt |

## IntFloat Rounding

Rounding modes: `SM32_TO_FP32_RNE=0` (ties to even), `SM32_TO_FP32_RNS=1` (stochastic using 7 PRNG bits). Exact only for |x| ≤ 2^24.

## IntInt Symmetry

Conversion works both ways (sign-magnitude ↔ two's complement). Two non-representable corner values: -2^31 ↔ -0. Mod1: INT32_SM32=3.

## IntAbs Hardware Bug

This encoding was intended for something else but due to a silicon bug computes two's complement abs. Software strongly encouraged to use SFPABS instead. abs(-2^31) returns -2^31. Mod1: INT32_ABS=2.

## NonContractualBehavior

Mod1 > 3 triggers NonContractualBehavior. Current silicon masks with `Mod1 &= 3`.

## VD Constraint

VD must be < 8 or == 16. Write guard: VD < 12 or DISABLE_BACKDOOR_LOAD.

**Example:**
```asm
SFPCAST 1, 2, MOD_INTFLOAT   ; LReg[2] = (float)SignMagToInt32(LReg[1])  (sign-mag → FP32)
SFPCAST 1, 2, MOD_INTINT     ; LReg[2] = SignMagToInt32(LReg[1])          (sign-mag → TC int32)
```

**Notes:** Tensix uses sign-magnitude integer representation internally, unlike two's complement in standard CPUs. These instructions convert between sign-magnitude and standard integer.
