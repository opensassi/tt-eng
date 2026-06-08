# Synchronization Instructions

## `STALLWAIT` – Stall Until Condition

`STALLWAIT BlockMask, ConditionMask` — Blocks selected instruction types at the Wait Gate until conditions are met.
- BlockMask (9 bits B0-B8): Each bit blocks a category of instructions (Miscellaneous, Unpacker, Packer, Vector/SFPU, Matrix/FPU, Scalar, Mover, TDMA-RISC, RISCV). B0 blocks Miscellaneous Unit, Mover, Scalar Unit, Packer, and Unpacker instructions.
- ConditionMask (13 bits C0-C12): C0=Scalar Unit has memory requests outstanding, C1=Unpacker 0 busy, C2=Unpacker 1 busy, C3=Packer busy, C4=Matrix Unit busy, C5=SrcA not Unpackers, C6=SrcB not Unpackers, C7=SrcA not MatrixUnit, C8=SrcB not MatrixUnit, C9=Mover busy, C10=RISCV store ordering, C11=Vector Unit busy, C12=Configuration Unit busy.
- The WaitGate introduces 1 cycle lag between condition met and block removal.
- STALLWAIT itself is blocked by all BlockMask bits (it stalls until the mask is cleared).
- NOP is special-cased: normally not blocked by individual block bits, but IS blocked when all BlockMask bits are set.

## WaitGate

Final frontend stage in Tensix pipeline. Strictly in-order. Holds instructions when: target unit is busy, thread mutex contended, SrcA/SrcB AllowedClient wrong, or explicit STALLWAIT/SEMWAIT asserted. Implements a latched-wait mechanism: once an instruction is waiting, the condition is captured and re-evaluated each cycle.

## `SyncUnit` – Semaphore Unit

Provides P (wait/decrement) and V (signal/increment) operations on 32-bit semaphores. Semaphores live in the Tensix coprocessor's sync unit, distinct from NoC semaphores.

SyncUnit handles mutexes, semaphores, and synchronization instructions. Throughput: ATGETM/ATRELM up to 3/cycle (different mutexes), SEM/SEMWAIT/STALLWAIT 1/cycle.
- 4 mutexes (indices 0, 2-4).
- Semaphores (8 total): {uint4_t Value, Max}.
- RISCV memory-mapped semaphore access at PC_BUF_BASE: reads return Value, writes with bit0=1 decrement, bit0=0 increment.

> **Blackhole-specific**: Compared to Wormhole, the Sync Unit in Blackhole gains a new STREAMWAIT instruction, changes the encoding of STALLWAIT's condition mask (15→13 bits), and reduces the number of mutexes from seven to four.

## `SETDVALID`

`SETDVALID` — Gives SrcA/SrcB banks to Matrix Unit. Flips Unpacker banks. Functional model shows FlipSrcA/FlipSrcB fields with SrcRow calculation. Blackhole implied format not fully characterized.

> **Note**: Documentation derived from Wormhole source; Blackhole encoding may differ.

## `CLEARDVALID`

`CLEARDVALID` — Gives SrcA/SrcB banks back to Unpackers. RESET mode = UnsupportedFunctionality (nondeterministic hangs — GitHub issue #22383). KeepReadingSameSrc option available. Executes in Matrix Unit (FPU).

> **Note**: Documentation derived from Wormhole source; Blackhole encoding may differ.

## `STREAMWAIT` – Stream Wait

`STREAMWAIT ConditionIndex, StreamSelect` — Wait for stream data to become available at a stream input. Streams are hardware FIFOs connecting unpacker/packer to NoC.
- ConditionIndex: selects which stream condition to wait on.
- StreamSelect: selects the specific stream to monitor.

## `STREAMWRCFG` – Stream Write Configuration

`STREAMWRCFG CfgIndex` — Move 32 bits from NoC Overlay to thread-agnostic backend configuration. The current thread's CFG_STATE_ID_StateID determines which configuration bank is written to. Functional model reads from NOC_STREAM_READ_REG and writes to Config[StateID][CfgIndex].

Latency: at least 5 cycles minimum.

> **Known bug**: Scheduling hazard exists when STREAMWRCFG is followed by an instruction that reads the same configuration register before the write completes. Ensure minimum 5 cycle separation or use intervening instructions.

## Manual TTSync

Per-core synchronization mechanism using dedicated hardware registers at `PC_BUF_BASE+4` (CoprocessorDoneCheck) and `PC_BUF_BASE+8` (MOPExpanderDoneCheck).
- **Write**: Store any value to trigger ordering.
- **Read**: Load returns undefined value after blocking until coprocessor is done.
- **Sequence**: A store followed by a load to the same register ensures the store is globally visible before proceeding.

> **Hardware bug**: Load address range conflicts can occur when the load address aliases with other register regions. Alternative: use SEMWAIT or STALLWAIT with appropriate condition mask bits instead of Manual TTSync for critical synchronization paths.

## Auto TTSync

Hardware-automated sync between compute and data-movement kernels. Tracks four resource types:
1. **Unpacker operations** — UNPACR, UNPACR_NOP variants
2. **Packer operations** — PACR, PACR_SETREG
3. **Matrix Unit operations** — FPU instructions
4. **Mover operations** — XMOV, XMOVI

Four automatically-handled ordering scenarios:
1. **Unpacker → Matrix Unit**: Auto-synchronizes SrcA/SrcB bank flips between Unpackers and Matrix Unit.
2. **Matrix Unit → Packer**: Auto-synchronizes Dst availability from Matrix Unit to Packers.
3. **Mover → Any**: Data movement from NoC to L1 completes before dependent compute instructions.
4. **Cross-thread dependencies**: Configured via TENSIX_TRISC_SYNC_* configuration fields.

Configuration is subdivided per instruction class (UNPACR, PACR, etc.) and mapped via RESOURCEDECL instruction. Address-to-resource mapping tables define which address ranges correspond to which resource classes.

> **Hardware bug**: In the store-then-load scenario (Manual TTSync), a fence instruction is required between store and load to prevent load reordering. Auto TTSync does not have this issue for tracked resources.
