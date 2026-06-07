# Miscellaneous Instructions

## ScalarUnit

GPRs: uint32_t GPRs[3][64] (one bank per thread). RISCV access at REGFILE_BASE. Race condition: RISCV writing GPR then pushing Tensix instruction can reorder — use SETDMAREG pair or STALLWAIT(C13). No internal pipelining — one instruction at a time. Issuing thread fully blocked while Scalar Unit busy. Instruction cycle cost: DMANOP=1, LOADIND/STOREREG/STOREIND≥3, ATSWAP/ATINCGET≥12, ATCAS≥15.

## MiscellaneousUnit

All instructions 1 cycle. Accepts one per thread per cycle. ADC manipulation, SETDVALID, NOP live here.

## Atomic Operations (Tensix Coprocessor)

These operate on 128-bit atomics in L1, distinct from NoC atomics.

| Mnemonic | Description |
|----------|-------------|
| `ATGETM` | Atomic get: read 128-bit from `Addr(ADRCR.xy, ADRCR.zw)`, mark for exclusive use. 7 mutexes (index 0, 2-7). Index 1 causes infinite wait. Reacquiring held mutex may wait. Round-robin fairness on release. |
| `ATRELM` | Atomic release: write 128-bit back, release exclusive lock. Releasing unheld mutex does nothing. Fairness: thread (i+1)%3 gets the lock. |
| `ATCAS` | Compare-and-swap on 128-bit L1 data. ≥15 cycles. Retries every 15+ cycles on failure. 4-bit compare/set. Uses Scalar Unit via L1 access port. |
| `ATSWAP` | Atomic swap on 128-bit L1 data. Up to 128-bit write from GPRs, 16-bit mask granularity. Completes when request is sent (async). SingleDataReg mode. Occupies Scalar Unit ≥3 cycles. 12-cycle throughput limit. |
| `ATINCGET` | Atomic increment and read result. 1-32 bit width, arbitrary increment. Returns original value. Needs STALLWAIT(C0) before reading result. 12-cycle throughput limit. |
| `ATINCGETPTR` | Atomic increment pointer and get. FIFO push/pop pointer semantics. REQUIRES bounded counters (not free-running 32-bit). Tests full/empty. ≥15 cycles. |
| `RMWCIB` | Read-modify-write CIB (configuration-in-buffer) register |

## ADDRCRXY / ADDRCRZW

Manipulate ADC X/Y and Z/W counters for Unpackers/Packers. ThreadOverride is UnsupportedFunctionality.

## Scalar Load/Store to L1

| Mnemonic | Description |
|----------|-------------|
| `LOADIND` | `Reg = MEM[Base + Offset × Stride]` — strided load from L1 |
| `LOADREG` | `Reg = MEM[Addr]` — direct load from L1 |
| `STOREIND` | `MEM[Base + Offset × Stride] = Reg` — strided store to L1 |
| `STOREREG` | `MEM[Addr] = Reg` — direct store to L1 |
| `SETDMAREG` | Load address register from immediate or special |
| `ADDDMAREG` / `SUBDMAREG` | Add/subtract DMA address registers |
| `MULDMAREG` | Multiply DMA address registers |
| `CMPDMAREG` | Compare DMA address registers |
| `SHIFTDMAREG` | Shift DMA address register |
| `BITWOPDMAREG` | Bitwise op on DMA registers |
| `DMANOP` | DMA no-op |
| `FLUSHDMA` | Flush pending DMA operations |

## Scalar Register Operations

| Mnemonic | Description |
|----------|-------------|
| `MOVB2A` | Move B register to A |
| `MOVA2D` | Move A register to D |
| `MOVB2D` | Move B register to D |
| `MOVD2A` | Move D register to A |
| `MOVD2B` | Move D register to B |
| `MOVDBGA2D` | Move debug A to D |
| `ZEROACC` | Zero accumulator (Dst) |
| `ZEROSRC` | Zero source A/B registers |
| `XMOV` | Async bulk copy from L1 (or /dev/null) to L1/config/NC IRAM. 16-byte aligned. STALLWAIT(C12) to wait for completion. |
| `TRNSPSRCB` | Transpose source B matrix |

## Semaphores (Coprocessor)

See [SyncUnit](../synchronization/README.md).

| Mnemonic | Description |
|----------|-------------|
| `SEMGET` | Decrements selected semaphores (not 'read'). |
| `SEMINIT` | Sets both Value and Max simultaneously. |
| `SEMPOST` | Increments value, clamped at Max. |
| `SEMWAIT` | Uses 9-bit BlockMask + 2-bit ConditionMask (C0=Value==0, C1=Value>=Max). Scheduling: need STALLWAIT(B1) before SEM ops for ordering. |

RISCV memory-mapped semaphore access at PC_BUF_BASE: reads return Value, writes with bit0=1 decrement, bit0=0 increment.

## Register File Descriptions

| Register | Description |
|----------|-------------|
| `LReg` | 16 × 32-wide vector registers (SFPU). Each lane is 32 bits. Two banks (A/B). |
| `Dst` | Accumulator: 4 banks × 96 entries × 128 bits. Holds matrix/vector results. |
| `SETC16` | Write to configuration register C16 (context-related). |

## Utility

| Mnemonic | Description |
|----------|-------------|
| `NOP` | Pipeline no-op |
| `REPLAY` | 32-entry per-thread replay buffer. Load/Exec modes. Sits after MOP Expander in pipeline. |
| `REG2FLOP_ADC` | GPR→ADC move (UnsupportedFunctionality, discouraged). |
| `REG2FLOP_Configuration` | GPR→THCON config via Scalar Unit (avoiding Configuration Unit contention). Blackhole: UnsupportedFunctionality. |
| `SETDVALID` | Mark output data as valid |
| `CLEARDVALID` | Clear data valid flag |
| `GATESRCRST` | Gate source reset |
| `CLREXPHIST` | Clear exception history |
