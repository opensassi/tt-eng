# `STOREREG` – Direct Scalar Store to MMIO

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `STOREREG DataReg, AddrLo`

**Operation:** Write 32 bits to MMIO register space at address `0xFFB00000 + (AddrLo << 2)`. AddrLo must be ≥ 0xFFB11000; values below this produce UndefinedBehavior.

**Completion:** Instruction completes when the write request is *sent*, not when it reaches the destination.
