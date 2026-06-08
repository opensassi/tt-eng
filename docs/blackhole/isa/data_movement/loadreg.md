# `LOADREG` – Direct Scalar Load from MMIO

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `LOADREG /* u6 */ ResultReg, /* u18 */ AddrLo`

**Operation:** Read 32 bits from MMIO register space at address `0xFFB00000 + (AddrLo << 2)`. The resulting address `0xFFB00000 + (AddrLo << 2)` must be ≥ `0xFFB11000`; addresses below this produce UndefinedBehavior. Equivalently, `AddrLo` must be ≥ `0x4400`.

**Completion:** Instruction completes when the read request is *sent*. Data is not yet available. Use `STALLWAIT(C0)` before reading the result.

**Backend:** Scalar Unit (ThCon). ≥3 cycles (possibly longer if the memory subsystem is busy).

**Encoding:** ![](../../../Diagrams/Out/Bits32_LOADREG.svg)

## Example

```asm
LOADREG r0, 0x4400   // Load from MMIO address 0xFFB11000 into GPR r0
LOADREG r1, 0x4480   // Load from MMIO address 0xFFB12000 into GPR r1
