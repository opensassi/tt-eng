# `vsad` – Vector Sum of Absolute Differences (SFPU) [Synthetic]

**Category:** SFPU Vector Utility (Compound Operation)

**Synthetic:** This documents a multi-instruction compound operation. No single `VSAD` opcode exists in the Tensix ISA. The operation is synthesized from SFPADD + SFPABS + SFPTRANSP + SFPMAD.

**Syntax:** `VSAD A_lreg, B_lreg, dst_lreg` — multi-instruction sequence (5+ cycles)

**SFPU mnemonic:** Implemented via multi-instruction sequence (no single `VSAD` instruction exists)

**Operation:** `sum = Σ|A[i] - B[i]|` over 32 vector lanes.

**Complete working sequence (5 instructions):**
```asm
; === VSAD: Vector Sum of Absolute Differences ===
; Inputs:  LReg[1] = A (32 × bfloat16), LReg[2] = B (32 × bfloat16)
; Outputs: LReg[5] = scalar sum (bfloat16)
; Clobbers: LReg[3], LReg[4], LReg[5]

; Cycle 1: A - B (lane-wise subtract on MAD sub-unit)
SFPADD 10, 1, 2, 3, MOD_SIGN_VC_NEG   ; LReg[3] = LReg[1] - LReg[2]  (VD=3, all lanes)

; Cycle 2: Absolute value (simple sub-unit)
SFPABS 12, 3, 4                        ; LReg[4] = Abs(LReg[3])       (VD=4)
; SFPABS passes NaN through unchanged (does not canonicalize)

; Cycles 3-5: Horizontal reduction across 32 lanes
; Step 1: Pairwise reduction via SFPTRANSP (MAD sub-unit)
SFPTRANSP 14, 4, 5, 6                  ; LReg[5] = reduce_pairs(LReg[4])

; Step 2: Accumulate partial sums via SFPMAD
SFPMAD 16, 5, 7, 8, 5                  ; LReg[5] = LReg[5] + LReg[7]  (accumulate)

; Step 3: Final horizontal add via SFPTRANSP
SFPTRANSP 18, 5, 8, 9                  ; LReg[5] = scalar_sum(LReg[5])
