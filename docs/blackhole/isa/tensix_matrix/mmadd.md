# `mmadd` / `DOTPV` – Matrix Multiply-Accumulate / Dot Product (FPU)

**Category:** Matrix Engine (FPU)

**FPU mnemonic:** `MVMUL` (accumulating) / `DOTPV`

**Syntax:**
```c
TT_MVMUL(((/* bool */ FlipSrcB) << 1) + /* bool */ FlipSrcA,
         /* bool */ BroadcastSrcBRow,
         /* u2 */ AddrMod,
         /* u10 */ DstRow)   ; matrix multiply-accumulate

TT_DOTPV(((/* bool */ FlipSrcB) << 1) + /* bool */ FlipSrcA,
         false,
         0,
         /* u2 */ AddrMod,
         /* u10 */ DstRow)   ; matrix multiply-accumulate (no broadcast)
