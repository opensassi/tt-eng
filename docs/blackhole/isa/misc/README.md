# Miscellaneous Instructions

## ScalarUnit

GPRs: uint32_t GPRs[3][64] (one bank per thread). RISCV access at REGFILE_BASE. Race condition: RISCV writing GPR then pushing Tensix instruction can reorder — use SETDMAREG pair or STALLWAIT(C13). No internal pipelining — one instruction at a time. Issuing thread fully blocked while Scalar Unit busy.

### Scalar Unit Instructions

#### DMANOP
- **Syntax**: `DMANOP`
- **Description**: DMA no-op. Occupies Scalar Unit for 1 cycle.
- **Operands**: None
- **Latency**: 1 cycle
- **Scheduling**: No restrictions. Can be used to align Scalar Unit timing.
- **Configuration**: None required.
- **Example**: `DMANOP`

#### LOADIND
- **Syntax**: `LOADIND DstReg, BaseReg, OffsetReg, Stride`
- **Description**: Strided load from L1: `DstReg = MEM[BaseReg + OffsetReg × Stride]`. Reads from L1 at the computed address and stores the result in the destination GPR.
- **Operands**:
  - `DstReg`: Destination GPR index (0-63)
  - `BaseReg`: Base address GPR index (0-63)
  - `OffsetReg`: Offset GPR index (0-63)
  - `Stride`: Stride value encoded in modifier field
- **Latency**: ≥3 cycles
- **Scheduling**: Issuing thread blocked until load completes. RAW hazard: subsequent instructions reading `DstReg` must wait for completion (auto-stalled on Blackhole; explicit STALLWAIT required on Wormhole).
- **Precondition**: `BaseReg` must be initialized via `SETDMAREG` prior to use.
- **Example**: `LOADIND R3, R0, R1, 4`

#### LOADREG
- **Syntax**: `LOADREG DstReg, Addr`
- **Description**: Direct load from L1: `DstReg = MEM[Addr]`. Reads a single 32-bit value from the specified L1 address.
- **Operands**:
  - `DstReg`: Destination GPR index (0-63)
  - `Addr`: L1 memory address (immediate)
- **Latency**: ≥3 cycles
- **Scheduling**: Issuing thread blocked until load completes.
- **Configuration**: None required.
- **Example**: `LOADREG R0, 0x10000`

#### STOREIND
- **Syntax**: `STOREIND SrcReg, BaseReg, OffsetReg, Stride`
- **Description**: Strided store to L1: `MEM[BaseReg + OffsetReg × Stride] = SrcReg`. Writes source GPR value to L1 at the computed address.
- **Operands**:
  - `SrcReg`: Source GPR index (0-63)
  - `BaseReg`: Base address GPR index (0-63)
  - `OffsetReg`: Offset GPR index (0-63)
  - `Stride`: Stride value encoded in modifier field
- **Latency**: ≥3 cycles
- **Scheduling**: Issuing thread blocked until store completes. Use `FLUSHDMA` or `STALLWAIT(C12)` if subsequent operations depend on data visibility in L1.
- **Precondition**: `BaseReg` must be initialized via `SETDMAREG`.
- **Example**: `STOREIND R0, R1, R2, 4`

#### STOREREG
- **Syntax**: `STOREREG SrcReg, Addr`
- **Description**: Direct store to L1: `MEM[Addr] = SrcReg`. Writes a single 32-bit value to the specified L1 address.
- **Operands**:
  - `SrcReg`: Source GPR index (0-63)
  - `Addr`: L1 memory address (immediate)
- **Latency**: ≥3 cycles
- **Scheduling**: Issuing thread blocked until store completes. Data may not be visible to other units until flushed.
- **Configuration**: None required.
- **Example**: `STOREREG R0, 0x10000`

#### SETDMAREG
- **Syntax**: `SETDMAREG DstReg, Src`
- **Description**: Load DMA address register from immediate or special register. Initializes address registers used by `LOADIND`/`STOREIND` and arithmetic DMA operations.
- **Operands**:
  - `DstReg`: Destination GPR (address register) index
  - `Src`: Source value (immediate or special register)
- **Latency**: 1 cycle
- **Scheduling**: Must precede any `LOADIND`/`STOREIND`/DMA arithmetic that uses the register. RISCV→GPR race condition: use `SETDMAREG` pair or `STALLWAIT(C13)` when writing from RISCV then immediately using in Tensix.
- **Configuration**: None required.
- **Example**: `SETDMAREG R0, 0x20000`

#### ADDDMAREG
- **Syntax**: `ADDDMAREG DstReg, SrcReg`
- **Description**: Add DMA address registers: `DstReg = DstReg + SrcReg`.
- **Operands**:
  - `DstReg`: Destination and first source GPR
  - `SrcReg`: Second source GPR
- **Latency**: 1 cycle
- **Scheduling**: RAW hazard on `DstReg`.
- **Example**: `ADDDMAREG R0, R1`

#### SUBDMAREG
- **Syntax**: `SUBDMAREG DstReg, SrcReg`
- **Description**: Subtract DMA address registers: `DstReg = DstReg - SrcReg`.
- **Operands**:
  - `DstReg`: Destination and first source GPR
  - `SrcReg`: Second source GPR
- **Latency**: 1 cycle
- **Example**: `SUBDMAREG R0, R1`

#### MULDMAREG
- **Syntax**: `MULDMAREG DstReg, SrcReg`
- **Description**: Multiply DMA address registers: `DstReg = DstReg × SrcReg`.
- **Operands**:
  - `DstReg`: Destination and first source GPR
  - `SrcReg`: Second source GPR
- **Latency**: 1 cycle
- **Example**: `MULDMAREG R0, R1`

#### CMPDMAREG
- **Syntax**: `CMPDMAREG SrcReg1, SrcReg2`
- **Description**: Compare DMA address registers. Sets condition flags based on comparison of two GPRs.
- **Operands**:
  - `SrcReg1`: First GPR to compare
  - `SrcReg2`: Second GPR to compare
- **Latency**: 1 cycle
- **Example**: `CMPDMAREG R0, R1`

#### SHIFTDMAREG
- **Syntax**: `SHIFTDMAREG DstReg, SrcReg, ShiftAmount`
- **Description**: Shift DMA address register: `DstReg = SrcReg << ShiftAmount` (or `>>` depending on modifier).
- **Operands**:
  - `DstReg`: Destination GPR
  - `SrcReg`: Source GPR
  - `ShiftAmount`: Shift amount (encoded in modifier field)
- **Latency**: 1 cycle
- **Example**: `SHIFTDMAREG R0, R1, 4`

#### BITWOPDMAREG
- **Syntax**: `BITWOPDMAREG DstReg, SrcReg, Op`
- **Description**: Bitwise operation on DMA registers: `DstReg = DstReg OP SrcReg` (AND, OR, XOR, NOT depending on modifier).
- **Operands**:
  - `DstReg`: Destination and first source GPR
  - `SrcReg`: Second source GPR
  - `Op`: Operation select (AND=00, OR=01, XOR=10, NOT=11)
- **Latency**: 1 cycle
- **Example**: `BITWOPDMAREG R0, R1`

#### FLUSHDMA
- **Syntax**: `FLUSHDMA`
- **Description**: Flush pending DMA operations. Ensures all prior `STOREIND`/`STOREREG` writes are visible in L1 before subsequent operations proceed.
- **Operands**: None
- **Latency**: Depends on pending operations (variable).
- **Scheduling**: Must be followed by `STALLWAIT(C12)` to guarantee completion.
- **Example**:
  ```
  FLUSHDMA
  STALLWAIT C12
  ```

---

## MiscellaneousUnit

All instructions 1 cycle. Accepts one per thread per cycle. ADC manipulation, SETDVALID, NOP live here.

#### NOP
- **Syntax**: `NOP`
- **Description**: Pipeline no-op. Consumes one issue slot; no side effects.
- **Operands**: None
- **Latency**: 1 cycle
- **Scheduling**: No restrictions. Useful for timing alignment or consuming issue bandwidth.
- **Example**: `NOP`

#### SETDVALID
- **Syntax**: `SETDVALID`
- **Description**: Mark output data as valid. Signals to downstream units (packers) that data in `Dst` is ready for consumption.
- **Operands**: None
- **Latency**: 1 cycle
- **Scheduling**: Must be issued after all data has been written to `Dst` and before any `PACR` instruction that reads from `Dst`.
- **Example**: `SETDVALID`

#### CLEARDVALID
- **Syntax**: `CLEARDVALID`
- **Description**: Clear data valid flag. Resets the DVALID state for the current context.
- **Operands**: None
- **Latency**: 1 cycle
- **Scheduling**: Should be issued before starting a new computation that will produce output.
- **Known Bugs**: **Blackhole**: `CLEARDVALID` in Reset mode = UnsupportedFunctionality. Behavior is undefined when used in certain reset configurations.
- **Example**: `CLEARDVALID`

#### GATESRCRST
- **Syntax**: `GATESRCRST`
- **Description**: Gate source reset. Resets the source gating logic for the thread.
- **Operands**: None
- **Latency**: 1 cycle

#### CLREXPHIST
- **Syntax**: `CLREXPHIST`
- **Description**: Clear exception history. Resets any recorded exception state for the thread.
- **Operands**: None
- **Latency**: 1 cycle

---

## ADDRCRXY / ADDRCRZW

Manipulate ADC X/Y and Z/W counters for Unpackers/Packers.

- **Syntax**: `ADDRCRXY SrcReg` / `ADDRCRZW SrcReg`
- **Operands**:
  - `SrcReg`: GPR containing the ADC index and increment value
- **Latency**: 1 cycle
- **Scheduling**: ThreadOverride is UnsupportedFunctionality. Each thread can only manipulate its own ADC counters; overriding to another thread's ADC produces undefined behavior.
- **Known Bugs**:
  - ThreadOverride → UnsupportedFunctionality
  - **Blackhole**: RDCFG hardware bug may affect ADC read-back correctness. Avoid back-to-back ADC reads without intervening cycles.
- **Example**: `ADDRCRXY R0`

---

## Atomic Operations (Tensix Coprocessor)

These operate on 128-bit atomics in L1, distinct from NoC atomics. All atomic operations use the Scalar Unit via the L1 access port. The address for all atomic operations is formed from `Addr(ADRCR.xy, ADRCR.zw)`.

### ATGETM
- **Syntax**: `ATGETM VDst, MutexIndex`
- **Description**: Atomic get — read 128-bit from `Addr(ADRCR.xy, ADRCR.zw)`, mark for exclusive use. On success, data is returned to `VDst` and the mutex is acquired.
- **Operands**:
  - `VDst`: Vector destination for the 128-bit data
  - `MutexIndex`: Mutex index (0, 2-7 are valid; index 1 causes infinite wait)
- **Latency**: ≥12 cycles
- **Scheduling**:
  - 7 mutexes (index 0, 2-7). Index 1 is reserved and causes infinite wait.
  - Reacquiring a held mutex may wait until released.
  - Round-robin fairness on release: thread (i+1)%3 gets priority.
  - Must use `STALLWAIT` before reading result data.
- **Precondition**: `ADRCR.xy` and `ADRCR.zw` must be configured to target L1 address.
- **Known Bugs**: Index 1 causes infinite wait — never use.
- **Example**:
  ```
  ADDRCRXY R0       ; Configure address X/Y
  ADDRCRZW R1       ; Configure address Z/W
  ATGETM V0, 2      ; Acquire mutex 2, read 128-bit to V0
  STALLWAIT C0      ; Wait for data ready
  ```

### ATRELM
- **Syntax**: `ATRELM VSrc, MutexIndex`
- **Description**: Atomic release — write 128-bit data from `VSrc` back to `Addr(ADRCR.xy, ADRCR.zw)`, release exclusive lock.
- **Operands**:
  - `VSrc`: Vector source containing 128-bit data to write
  - `MutexIndex`: Mutex index to release (0, 2-7)
- **Latency**: ≥12 cycles
- **Scheduling**:
  - Releasing an unheld mutex does nothing (no error, no side effect).
  - After release, thread (i+1)%3 is selected for fairness.
- **Precondition**: `ADRCR.xy`/`ADRCR.zw` must match the address used by the corresponding `ATGETM`.
- **Example**:
  ```
  ADDRCRXY R0
  ADDRCRZW R1
  ATRELM V0, 2      ; Write V0 back, release mutex 2
  ```

### ATCAS
- **Syntax**: `ATCAS VDst, VSrc, MutexIndex`
- **Description**: Compare-and-swap on 128-bit L1 data. Compares the value at `Addr(ADRCR.xy, ADRCR.zw)` with the expected value; if equal, swaps in the value from `VSrc`. The actual value at the address is returned in `VDst`. Uses 4-bit compare/set mask.
- **Operands**:
  - `VDst`: Vector destination for the current (pre-CAS) value
  - `VSrc`: Vector source containing the new value
  - `MutexIndex`: Mutex index
- **Latency**: ≥15 cycles. Retries every 15+ cycles on failure.
- **Scheduling**:
  - Uses Scalar Unit via L1 access port. Issuing thread is fully blocked during operation.
  - On CAS failure, hardware retries automatically every 15+ cycles.
- **Precondition**: `ADRCR.xy`/`ADRCR.zw` must be set. 4-bit compare/set mask must be configured in a modifier register.
- **Example**:
  ```
  ADDRCRXY R0
  ADDRCRZW R1
  ATCAS V0, V1, 2   ; CAS on mutex 2, expected in V0, new in V1
  STALLWAIT C0      ; Wait for result
  ```

### ATSWAP
- **Syntax**: `ATSWAP VDst, VSrc, MutexIndex, Mask`
- **Description**: Atomic swap on 128-bit L1 data. Writes up to 128-bit from GPRs to `Addr(ADRCR.xy, ADRCR.zw)` with 16-bit mask granularity. Completes asynchronously when the request is sent. Operates in SingleDataReg mode.
- **Operands**:
  - `VDst`: Vector destination
  - `VSrc`: Vector source containing data to write
  - `MutexIndex`: Mutex index
  - `Mask`: 16-bit write mask (each bit enables 16 bits of the 128-bit write)
- **Latency**: Occupies Scalar Unit ≥3 cycles. Throughput-limited to one per 12 cycles.
- **Scheduling**:
  - Completes when request is sent (asynchronous). Use `STALLWAIT` if ordering with subsequent operations is required.
  - 12-cycle minimum throughput: back-to-back `ATSWAP` must be spaced ≥12 cycles apart.
  - Uses Scalar Unit — thread blocked while Scalar Unit is busy.
- **Precondition**: `ADRCR.xy`/`ADRCR.zw` must be configured.
- **Example**:
  ```
  ADDRCRXY R0
  ADDRCRZW R1
  ATSWAP V0, V1, 2, 0xFFFF   ; Swap all 128 bits on mutex 2
  ```

### ATINCGET
- **Syntax**: `ATINCGET VDst, VSrc, Width, Increment`
- **Description**: Atomic increment and read result. Atomically increments a value at `Addr(ADRCR.xy, ADRCR.zw)` by `Increment` and returns the original value in `VDst`. Width is 1-32 bits; arbitrary increment value.
- **Operands**:
  - `VDst`: Vector destination for original (pre-increment) value
  - `VSrc`: Vector source
  - `Width`: Bit width of the counter (1-32)
  - `Increment`: Value to increment by
- **Latency**: ≥12 cycles (throughput-limited)
- **Scheduling**:
  - `STALLWAIT(C0)` required before reading result from `VDst`.
  - 12-cycle throughput limit between successive `ATINCGET` instructions.
  - Uses Scalar Unit — issuing thread blocked while busy.
- **Precondition**: `ADRCR.xy`/`ADRCR.zw` must be configured.
- **Example**:
  ```
  ADDRCRXY R0
  ADDRCRZW R1
  ATINCGET V0, V1, 32, 1   ; Atomically increment 32-bit counter by 1
  STALLWAIT C0              ; Wait for original value
  ```

### ATINCGETPTR
- **Syntax**: `ATINCGETPTR VDst, VSrc, Width`
- **Description**: Atomic increment pointer and get. Provides FIFO push/pop pointer semantics with bounded counters — tests full/empty conditions.
- **Operands**:
  - `VDst`: Vector destination for original pointer value
  - `VSrc`: Vector source
  - `Width`: Bit width (must use bounded counters, not free-running 32-bit)
- **Latency**: ≥15 cycles
- **Scheduling**:
  - **REQUIRES** bounded counters. Behavior with free-running (unbounded) 32-bit counters is undefined.
  - Auto-tests full/empty conditions; may stall if FIFO is full (on push) or empty (on pop).
  - Uses Scalar Unit.
- **Precondition**: `ADRCR.xy`/`ADRCR.zw` must be configured. Counter bounds must be preconfigured.
- **Known Bugs**: Free-running 32-bit counters produce undefined behavior — always configure bounds.
- **Example**:
  ```
  ADDRCRXY R0
  ADDRCRZW R1
  ATINCGETPTR V0, V1, 8    ; Atomic 8-bit FIFO pointer increment
  STALLWAIT C0
  ```

### RMWCIB
- **Syntax**: `RMWCIB Reg, Value`
- **Description**: Read-modify-write CIB (configuration-in-buffer) register. Atomically reads a CIB register, applies a modification, and writes the result back.
- **Operands**:
  - `Reg`: CIB register index
  - `Value`: Value to modify with
- **Latency**: ≥3 cycles
- **Scheduling**: Uses Scalar Unit. Thread blocked while operation is in progress.
- **Example**: `RMWCIB CIB0, R0`

---

## Semaphores (Coprocessor)

See [SyncUnit](../synchronization/README.md).

Each semaphore has a `Value` (current count, readable) and `Max` (maximum clamp value). Software should use `STALLWAIT(B1)` before SEM operations for correct ordering.

### SEMGET
- **Syntax**: `SEMGET SemIdx, BlockMask`
- **Description**: Decrements selected semaphores (not 'read'). For each bit set in `BlockMask`, the corresponding semaphore's `Value` is decremented (clamped at 0). Does NOT return the value to a register.
- **Operands**:
  - `SemIdx`: Semaphore index
  - `BlockMask`: 9-bit mask selecting which semaphore blocks to operate on
- **Latency**: 1 cycle (Sync Unit)
- **Scheduling**: `STALLWAIT(B1)` recommended before `SEMGET` for ordering. If semaphore value is 0, decrement does nothing (value stays at 0).
- **Precondition**: Semaphore must be initialized via `SEMINIT` before use.
- **Example**:
  ```
  STALLWAIT B1       ; Ordering barrier
  SEMGET 0, 0x001    ; Decrement semaphore 0
  ```

### SEMINIT
- **Syntax**: `SEMINIT SemIdx, Value, Max`
- **Description**: Initialize a semaphore. Sets both `Value` and `Max` simultaneously. Must be called before any other semaphore operation on the given index.
- **Operands**:
  - `SemIdx`: Semaphore index
  - `Value`: Initial value (must be ≤ Max)
  - `Max`: Maximum clamp value
- **Latency**: 1 cycle
- **Scheduling**: Must be executed before `SEMGET`, `SEMPOST`, or `SEMWAIT` for the same semaphore index.
- **Example**: `SEMINIT 0, 0, 1    ; Initialize semaphore 0 with value 0, max 1`

### SEMPOST
- **Syntax**: `SEMPOST SemIdx`
- **Description**: Increments semaphore value, clamped at Max. Atomically adds 1 to the semaphore `Value`, but the result will not exceed the `Max` set by `SEMINIT`.
- **Operands**:
  - `SemIdx`: Semaphore index
- **Latency**: 1 cycle
- **Scheduling**: `STALLWAIT(B1)` recommended before `SEMPOST` for ordering.
- **Example**:
  ```
  STALLWAIT B1
  SEMPOST 0          ; Increment semaphore 0
  ```

### SEMWAIT
- **Syntax**: `SEMWAIT SemIdx, BlockMask, ConditionMask`
- **Description**: Wait on semaphore condition. Blocks the thread until the selected semaphore meets the specified condition. Uses 9-bit `BlockMask` + 2-bit `ConditionMask`:
  - C0 (0b01): wait until `Value == 0`
  - C1 (0b10): wait until `Value >= Max`
- **Operands**:
  - `SemIdx`: Semaphore index
  - `BlockMask`: 9-bit mask
  - `ConditionMask`: 2-bit condition selection
- **Latency**: Variable (depends on when condition is met)
- **Scheduling**: `STALLWAIT(B1)` required before `SEMWAIT` for correct ordering. Thread is blocked until condition is satisfied.
- **Precondition**: Semaphore must be initialized first.
- **Known Bugs**: RISCV memory-mapped semaphore access at `PC_BUF_BASE`: reads return `Value`, writes with bit0=1 decrement, bit0=0 increment.
- **Example**:
  ```
  STALLWAIT B1
  SEMWAIT 0, 0x001, 0x01   ; Wait until semaphore 0 == 0
  ```

---

## Scalar Load/Store to L1

All L1 load/store instructions use the Scalar Unit. The issuing thread is fully blocked while the operation is in progress.

| Mnemonic | Syntax | Description | Latency |
|----------|--------|-------------|---------|
| `LOADIND` | `LOADIND DstReg, BaseReg, OffsetReg, Stride` | `Reg = MEM[Base + Offset × Stride]` — strided load from L1 | ≥3 cycles |
| `LOADREG` | `LOADREG DstReg, Addr` | `Reg = MEM[Addr]` — direct load from L1 | ≥3 cycles |
| `STOREIND` | `STOREIND SrcReg, BaseReg, OffsetReg, Stride` | `MEM[Base + Offset × Stride] = Reg` — strided store to L1 | ≥3 cycles |
| `STOREREG` | `STOREREG SrcReg, Addr` | `MEM[Addr] = Reg` — direct store to L1 | ≥3 cycles |
| `SETDMAREG` | `SETDMAREG DstReg, Src` | Load address register from immediate or special | 1 cycle |
| `ADDDMAREG` | `ADDDMAREG DstReg, SrcReg` | Add DMA address registers | 1 cycle |
| `SUBDMAREG` | `SUBDMAREG DstReg, SrcReg` | Subtract DMA address registers | 1 cycle |
| `MULDMAREG` | `MULDMAREG DstReg, SrcReg` | Multiply DMA address registers | 1 cycle |
| `CMPDMAREG` | `CMPDMAREG SrcReg1, SrcReg2` | Compare DMA address registers | 1 cycle |
| `SHIFTDMAREG` | `SHIFTDMAREG DstReg, SrcReg, ShiftAmount` | Shift DMA address register | 1 cycle |
| `BITWOPDMAREG` | `BITWOPDMAREG DstReg, SrcReg, Op` | Bitwise op on DMA registers | 1 cycle |
| `DMANOP` | `DMANOP` | DMA no-op | 1 cycle |
| `FLUSHDMA` | `FLUSHDMA` | Flush pending DMA operations | Variable |

**Scheduling Notes** (all Scalar Ld/St):
- Issuing thread fully blocked while Scalar Unit busy.
- `SETDMAREG` must precede `LOADIND`/`STOREIND`/DMA arithmetic.
- `FLUSHDMA` requires `STALLWAIT(C12)` to guarantee completion.
- **Blackhole**: Auto-stall for RAW hazards on GPRs handled by hardware. **Wormhole**: requires explicit `STALLWAIT`.
- **Precondition**: Address registers must be initialized via `SETDMAREG`. Stride values must be preconfigured for strided operations.

**Example**:
```asm
SETDMAREG R0, 0x20000
SETDMAREG R1, 16
LOADIND R3, R0, R1, 4   ; R3 = MEM[0x20000 + 16*4]
