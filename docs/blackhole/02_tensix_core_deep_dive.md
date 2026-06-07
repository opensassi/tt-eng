# Tensix Core Deep Dive

## Overview

Each Tensix tile contains the components needed to execute a complete pipeline stage: data movement, computation, and result write-back. The tile operates at 1.35 GHz.

## Per-Core Components

```
+------------------------------------------------------+
|  Tensix Tile (1.35 GHz)                              |
|                                                      |
|  +------------------+  +-------------------------+   |
|  | Baby RISC-V B    |  | Baby RISC-V T0 (compute)|   |
|  | (data movement)  |  | Baby RISC-V T1 (compute)|   |
|  | Baby RISC-V NC   |  | Baby RISC-V T2          |   |
|  | (data movement)  |  |   (compute + vector ISA)|   |
|  +------------------+  +-------------------------+   |
|                                                      |
|  +------------------------------------------------+  |
|  | Tensix Coprocessor                              |  |
|  | +--------+ +--------+ +--------+ +--------+    |  |
|  | |Unpacker| |Matrix  | |Vector  | |Packer  |    |  |
|  | | x2     | |Engine  | |Engine  | | x4     |    |  |
|  | +--------+ |(FPU)   | |(SFPU)  | +--------+    |  |
|  |            +--------+ +--------+                |  |
|  +------------------------------------------------+  |
|                                                      |
|  +------------------------------------------------+  |
|  | L1 SRAM: 1536 KiB (software-managed)            |  |
|  | +------------+ +----------+ +-----------------+ |  |
|  | | CB Buffers | | Workspace| | Kernel Text/Data| |  |
|  | +------------+ +----------+ +-----------------+ |  |
|  +------------------------------------------------+  |
|                                                      |
|  +------------------+  +-------------------------+   |
|  | NoC 0 NIU        |  | NoC 1 NIU              |   |
|  | X-first routing  |  | Y-first routing        |   |
|  +------------------+  +-------------------------+   |
+------------------------------------------------------+
```

## Baby RISC-V Cores (5 per tile)

Five 32-bit in-order single-issue RISC-V cores. Each executes one instruction per cycle at 1.35 GHz. They are optimized for area/power, not raw performance — their role is to orchestrate the NoC and coprocessor.

| Core | Role | Local Data RAM | Vector support |
|------|------|:---:|:---:|
| RISCV B | Data movement (NoC reads/writes) | 8 KiB | No |
| RISCV NC | Data movement (NoC reads/writes) | 8 KiB | No |
| RISCV T0 | Compute kernel orchestration | 4 KiB | No |
| RISCV T1 | Compute kernel orchestration | 4 KiB | No |
| RISCV T2 | Compute + vector kernel orchestration | 4 KiB | Yes (V extension) |

**Pipeline**: 3-stage (FETCH → EX1 → LSU/EX2 → Retire). In-order frontend, out-of-order execution within EX1/EX2, in-order retirement.

**Instruction set**: RV32IM + Zicsr + Zaamo + Zba + Zbb + partial F/Zfh + partial V (T2 only). Plus bespoke `.ttinsn` extension for pushing Tensix coprocessor instructions.

## Matrix Engine (FPU)

- Performs low-precision matrix multiply-accumulate operations
- Tile size: 32x32 elements (software-defined tile dimensions common)
- Supports INT8, INT16, BFLOAT16, TF32 formats
- Primary workhorse for AI compute

## Vector Engine (SFPU)

- 32-wide SIMD engine, 32-bit lanes (16384-bit total width)
- Supports FP32 arithmetic and 32-bit integer operations
- 5 sub-units: load, simple, MAD, round, store
- `SFPLOADMACRO` can chain multiple sub-units in one cycle

Key instructions: `SFPADD`, `SFPMUL`, `SFPMAD`, `SFPMUL24`, `SFPIADD`, `SFPABS`, `SFPMOV`, `SFPLOAD`, `SFPSTORE`, `SFPSHFT`, `SFPTRANSP`, `SFPAND`, `SFPOR`, `SFPXOR`, `SFPNOT`, `SFPLUT`, `SFPSTOCHRND`, `SFPCAST`, `SFPENCC` (conditional execution), `SFPLOADI` (immediate load).

## L1 Memory (1536 KiB)

- Software-managed scratchpad (no cache coherence)
- Partitioned into: circular buffers (CBs), kernel code/data, workspace
- 16 banks, 128-bit wide data path
- Accessible via NoC from any other tile
- Address range: `0x0000_0000` to `0x0017_FFFF`

## Limitations

- No hardware cache coherence between cores
- No branch predictor beyond simple static prediction
- Instructions execute only from L1 (not from DRAM or NoC)
- Stores to L1 have coalescing restrictions (must target same 16-byte aligned region)
- L0 data cache is only 64 bytes per core, not coherent
