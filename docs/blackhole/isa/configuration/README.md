# Configuration Instructions

## `RDCFG` – Read Configuration

**Syntax:** `RDCFG Addr, Dest`

Read from configuration space into a destination register.

> **HARDWARE BUG:** Simultaneous RDCFG from multiple threads causes all but one to be silently dropped. Software must serialize RDCFG accesses.

## `WRCFG` – Write Configuration

**Syntax:** `WRCFG Addr, Value`

Write to Tensix coprocessor configuration space. Covers matrix engine, vector engine, unpacker, packer, and backend pipeline settings.

**Scheduling:** WRCFG (2 cycles, pipelined) does NOT block the issuing thread. However, the next instruction must be a NOP before consuming the written config value.

## `CFGSHIFTMASK` – Configuration Shift Mask

Generate address mask for configuration access with shift offset. Used internally by `WRCFG`/`RDCFG` for indexed register arrays.

## `RMWCIB` – Read-Modify-Write CIB

**Syntax:** `RMWCIB0-3 Mask, Value`

Read-modify-write CIB (Configuration Intersection Bus). Writes up to 8 bits to thread-agnostic config. 4 variants (RMWCIB0-3 encode Index1). Mask semantics: `(NewValue & Mask) | (OldValue & ~Mask)`. 1 cycle, IPC=1.

## `SETC16` – Set Thread Config (16-bit)

**Syntax:** `SETC16 Addr, Value`

SETC16 writes 16 bits to ThreadConfig (not Config). Bound-checked against THD_STATE_SIZE. Maps to "Registers for THREAD" section of cfg_defines.h. 1 cycle.

## `BackendConfiguration`

Configuration space for the Tensix backend pipeline:
- Matrix engine tile dimensions and data formats
- Accumulator (Dst) buffer sizes
- Output data format and rounding modes
- Pipeline flush and drain controls

**Data model:** Config space: `Config[2][N]` for per-bank config, `ThreadConfig[3][N]` for per-thread config. `CFG_STATE_ID_StateID` determines which Config bank WRCFG/RDCFG targets.

## `ConfigurationUnit`

Overview of the full configuration register space. Configuration is organized into regions:
- Global control
- Unpacker config (per unpacker)
- Matrix engine config
- Vector engine config
- Packer config (per packer)
- Output config
- MOP expander config
- Semaphore/stream config

## RISCV Software Race Conditions

**Danger:** RISCV write to config (sw) then push instruction to thread can reorder. **Danger:** push instruction then RISCV write to config can execute before the instruction.

Three mitigations:
1. fence between sw and push
2. STALLWAIT(C13)
3. use WRCFG from Tensix thread instead of RISCV sw

See [BackendConfiguration.md](../../../external/tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/BackendConfiguration.md).
