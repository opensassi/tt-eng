# `LOADREG` – Direct Scalar Load from MMIO

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `LOADREG ResultReg, AddrLo`

**Operation:** Read 32 bits from MMIO register space at address `0xFFB00000 + (AddrLo << 2)`. AddrLo must be ≥ 0xFFB11000; values below this produce UndefinedBehavior.

**Completion:** Instruction completes when the read request is *sent*. Data is not yet available. Use `STALLWAIT(C0)` before reading the result.

**Backend:** Scalar Unit (ThCon). ≥3 cycles.
