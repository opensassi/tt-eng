# `vsad` – Vector Sum of Absolute Differences (SFPU)

**Category:** SFPU Vector Utility

**SFPU mnemonic:** Implemented via multi-instruction sequence (no single `VSAD` instruction exists)

**Operation:** `sum = Σ|A[i] - B[i]|` over 32 vector lanes.

Sequence breakdown (5 instructions):
```asm
; Cycle 1: A - B (lane-wise subtract)
SFPADD 10, 1, 2, 3, MOD_SIGN_VC_NEG   ; LReg[3] = LReg[1] - LReg[2]
; Cycle 2: Absolute value
SFPABS 3, 4                            ; LReg[4] = Abs(LReg[3])
; Cycle 3-4: Conditional flags + accumulation
SFPPUSHC ...                           ; Set up reduction flags
SFPMAD ...                             ; Accumulate
; Cycle 5: Horizontal add across lanes
SFPTRANSP ...                          ; Reduce 32 lanes to scalar
```

**Total latency:** ~5-8 cycles depending on reduction strategy (vs. 1 cycle for `psadbw` on x86)

**Register budget:** 3-4 LReg registers (A, B, temp, accumulator)

**x86 Equivalent:** `psadbw` (MMX/SSE2) — single instruction on x86

**Usage in VVC:** Motion estimation SAD computation, mode decision cost calculation.

**Notes:**
- No single-instruction SAD exists on Tensix. Must be synthesized from subtract + absolute value + horizontal add sequence using SFPU arithmetic and conditional execution.
- For best throughput, batch multiple SAD computations across available LReg registers before reducing.
- The conditional accumulation pattern can use `SFPENCC`/`SFPSETCC` predication (see [sfp-pred.md](tensix_vector/sfp-pred.md)) or a manual `SFPMAD` loop.
- Expected performance: ~0.4 SADs/cycle amortized when batched (vs. 1 SAD/cycle for `psadbw` on x86).
