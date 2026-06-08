# `STOREREG` – Direct Scalar Store to MMIO

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `STOREREG /* u6 */ DataReg, /* u18 */ AddrLo`

**Operation:** Write 32 bits from the addressed Tensix GPR (GPRs[CurrentThread][DataReg]) to MMIO register space at address `0xFFB00000 + (AddrLo << 2)`. AddrLo must be ≥ `0xFFB11000`; values below this produce UndefinedBehavior.

**Completion:** Instruction completes when the write request is *sent*, not when it reaches the destination. Until the write-request subsequently reaches the MMIO device, clients other than the Scalar Unit will not observe the write.

**Backend execution unit:** Scalar Unit (ThCon)

## Performance

The instruction occupies the Scalar Unit (ThCon) for at least three cycles, possibly longer if the memory subsystem is busy.

## Example

```asm
STOREREG R0, 0xFFB11000
