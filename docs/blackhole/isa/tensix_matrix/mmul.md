# `mmul` / `MVMUL` – Matrix Multiply (FPU)

**Category:** Matrix Engine (FPU)

**FPU mnemonic:** `MVMUL`

**Syntax:**
```c
TT_MVMUL(((FlipSrcB) << 1) | FlipSrcA, BroadcastSrcBRow, AddrMod, DstRow)
