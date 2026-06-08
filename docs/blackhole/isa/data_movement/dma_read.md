# `dma_read` – TDMA Bulk Data Move (Register Programming Sequence)

**Category:** Data Movement (TDMA-RISC)

**Category Note:** This is a register programming *sequence* dispatched via the TDMA-RISC command processor, not a single instruction mnemonic. The TDMA-RISC coprocessor offloads the Baby RISC-V data-movement core.

**Stub Status:** This file targets Blackhole but is derived from WormholeB0 documentation (`TDMA-RISC.md`, `Mover.md`). No BlackholeA0-specific register maps were available at time of writing. Behavior is presumed compatible with WormholeB0 until confirmed otherwise.

---

## Syntax (Register Programming Sequence)

A DMA data move is initiated by writing five MMIO registers in sequence, then writing the command opcode:

