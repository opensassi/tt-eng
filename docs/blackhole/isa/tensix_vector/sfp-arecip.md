# `SFPARECIP` – Approximate Reciprocal and Exponential

**Category:** SFPU Special Function (new in Blackhole)

**Syntax:** `SFPARECIP VB, VC, VD, Mod1`

## Modes

| Mode | Operation |
|------|-----------|
| Reciprocal | `VD = Approx(1.0 / VC)` |
| Conditional | `VD = (VB <= -0) ? Approx(1.0 / Abs(VC)) : VC` |
| Exponential | `VD = Approx(e^Abs(VC)) × (VC <= -0 ? -1 : +1)` |

## Mod1 Constants

| Constant | Value | Mode |
|----------|:-----:|------|
| `SFPARECIP_MOD1_RECIP` | 0 | Reciprocal |
| `SFPARECIP_MOD1_COND_RECIP` | 1 | Conditional Reciprocal |
| `SFPARECIP_MOD1_EXP` | 2 | Exponential |

## Approximation Accuracy

**Reciprocal:** `0.9944 × 1/x < ApproxRecip(x) < 1.0054 × 1/x` for 2^-126 ≤ x < 2^126. ApproxRecip(1.0) = 0.99609375.

**Exponential:** `0.9922 × e^x < ApproxExp(x) < 1.016 × e^x` for 0 ≤ x < 2. ApproxExp(1.0) = 2.703125.

## Range Limits

- **Recip:** Input < 2^-126 → Inf; input ≥ 2^126 → 0.
- **Exp:** Input < 2^-126 → 1.0; input ≥ 2 → not useful (software strongly discouraged).

## Sign Handling per Mode

- **RECIP:** Sign removed, re-joined.
- **COND_RECIP:** Sign removed, NOT re-joined (produces only positive results).
- **EXP:** Sign removed, re-joined (gives sign(x) × e^|x|, not e^x).

## VD Constraint

VD must be < 8 or == 16.

## Future Portability

Future architectures might change approximation formulas. Portable software should not rely on exact bit patterns.

**Latency:** 1 cycle, IPC=1

**New in Blackhole** — not available on Wormhole.

**x86 Equivalent:** `vrcp14ps` / `vexp2ps`

**Example:**
```asm
SFPARECIP 0, 1, 2, MOD_RECIP   ; LReg[2] = Approx(1.0 / LReg[1])  (approximate reciprocal)
SFPARECIP 0, 1, 2, MOD_EXP     ; LReg[2] = Approx(e^|LReg[1]|) × sign(LReg[1])
```
