# Synchronization Instructions

## `STALLWAIT` – Stall Until Condition

STALLWAIT BlockMask, ConditionMask — Blocks selected instruction types at the Wait Gate until conditions are met.
- BlockMask (9 bits B0-B8): Each bit blocks a category of instructions (Miscellaneous, Unpacker, Packer, Vector/SFPU, Matrix/FPU, Scalar, Mover, TDMA-RISC, RISCV). Bit 0 blocks all.
- ConditionMask (15 bits C0-C14): C0=LOADIND/LOADREG/ATINCGET data ready, C1=SEMWAIT, C2=Stream monitor, C3=Stream data available, C4=Stream wait, C5=Cell ready, C6=Packers FIFO, C7=Dest available, C8=Thread sync, C9=C10=C11=SrcA/B bank ownership, C12=Mover idle, C13=RISCV store ordered, C14=Tensix sync.
- The WaitGate introduces 1 cycle lag between condition met and block removal.
- STALLWAIT itself is blocked by all BlockMask bits (it stalls until the mask is cleared).
- NOP is special-cased: if all BlockMask bits are set, STALLWAIT does NOT block NOP.

## WaitGate

Final frontend stage in Tensix pipeline. Strictly in-order. Holds instructions when: target unit is busy, thread mutex contended, SrcA/SrcB AllowedClient wrong, or explicit STALLWAIT/SEMWAIT asserted. Implements a latched-wait mechanism: once an instruction is waiting, the condition is captured and re-evaluated each cycle.

## `SyncUnit` – Semaphore Unit

Provides P (wait/decrement) and V (signal/increment) operations on 32-bit semaphores. Semaphores live in the Tensix coprocessor's sync unit, distinct from NoC semaphores.

SyncUnit handles mutexes, semaphores, and synchronization instructions. Throughput: ATGETM/ATRELM up to 3/cycle (different mutexes), SEM/SEMWAIT/STALLWAIT 1/cycle.
- 7 mutexes (indices 0, 2-7). Index 1 causes infinite wait.
- Semaphores (8 total): {uint4_t Value, Max}.
- RISCV memory-mapped semaphore access at PC_BUF_BASE: reads return Value, writes with bit0=1 decrement, bit0=0 increment.

## `SETDVALID`

SETDVALID — Gives SrcA/SrcB banks to Matrix Unit. Flips Unpacker banks. Functional model shows FlipSrcA/FlipSrcB fields with SrcRow calculation. Blackhole implied format not fully characterized.

## `CLEARDVALID`

CLEARDVALID — Gives SrcA/SrcB banks back to Unpackers. RESET mode = UnsupportedFunctionality (nondeterministic hangs — GitHub issue #22383). KeepReadingSameSrc option available. Executes in Matrix Unit (FPU).

## `STREAMWAIT` – Stream Wait

Wait for stream data to become available at a stream input. Streams are hardware FIFOs connecting unpacker/packer to NoC.

## `STREAMWRCFG` – Stream Write Configuration

Configure how streaming writes work (target address, stride, count).

## Manual TTSync

Per-core synchronization mechanism using dedicated hardware registers (`0xFFE8_0004-001F`). Write to signal, read to wait. Used for core-to-core handshake within a Tensix tile.

## Auto TTSync

Hardware-automated sync between compute and data-movement kernels. Eliminates the need for explicit sync instructions in many pipeline patterns.
