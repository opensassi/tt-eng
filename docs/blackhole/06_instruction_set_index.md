# Tensix Instruction Set Index — Complete Reference

> **Register conventions:** SFPU vector instructions operate on `LReg[0..16]` (32 lanes × 32-bit each): `LReg[8]=0.8373f`, `LReg[9]=0`, `LReg[10]=1.0f` (read-only). Matrix (FPU) instructions use `SrcA`/`SrcB` staging buffers (loaded via Unpackers) and `Dst` accumulator (512×32-bit or 1024×16-bit). Most SFPU instructions require 16-byte aligned LReg operands. Operand types and full syntax are documented in each instruction's detail page.

## Table of Contents
- [Baby RISC-V Base](#baby-risc-v-base)
- [SFPU Vector Instructions](#sfpu-vector-instructions)
- [Tensix Matrix (FPU) Instructions](#tensix-matrix-fpu-instructions)
- [Data Movement (NoC / DMA)](#data-movement)
- [Circular Buffer Instructions](#circular-buffer)
- [Scalar Load/Store / Register Move](#scalar-loadstore--register-move)
- [Unpacker Instructions](#unpacker)
- [Packer Instructions](#packer)
- [Synchronization Instructions](#synchronization)
- [Atomic Operations](#atomic-operations)
- [Semaphore Operations](#semaphore-operations)
- [Configuration Instructions](#configuration)
- [MOP Expander Instructions](#mop-expander)
- [Other / Utility](#other--utility)

---

## Baby RISC-V Base

[rv32im/README.md](isa/rv32im/README.md). Standard RV32IM + Zicsr + Zaamo + Zba + Zbb + partial F/Zfh + partial V (T2 only) + `.ttinsn` extension.

## SFPU Vector Instructions

All instructions operate on 32-wide lanes (32-bit each), 1.35 GHz. `IPC=1` unless noted.

### FP32 Arithmetic

| Mnemonic | Description | x86 EQ | Lat | Page |
|----------|-------------|--------|:---:|------|
| `SFPADD` | Vector FP32 add/sub | `vaddps` / `vsubps` | 2 cyc | [vadd](isa/tensix_vector/vadd.md) |
| `SFPADD` (sign) | Vector FP32 subtract | `vsubps` | 2 cyc | [vsub](isa/tensix_vector/vsub.md) |
| `SFPMUL` | Vector FP32 multiply | `vmulps` | 2 cyc | [vmul](isa/tensix_vector/vmul.md) |
| `SFPMAD` | Vector FP32 multiply-accumulate | `vfmadd231ps` | 2 cyc | [vmac](isa/tensix_vector/vmac.md) |
| `SFPMAD` (indirect) | Non-uniform lane MAD | — | 2 cyc | [vmac](isa/tensix_vector/vmac.md) |
| `SFPADDI` | VD += Imm16 (BF16→FP32) | — | 2 cyc | [sfp-addi](isa/tensix_vector/sfp-addi.md) |
| `SFPMULI` | VD *= Imm16 (BF16→FP32) | — | 2 cyc | [sfp-muli](isa/tensix_vector/sfp-muli.md) |
| `SFPLUT` | 8-entry LUT interpolated lookup | — | 2 cyc | [sfp-lut](isa/tensix_vector/sfp-lut.md) |
| `SFPLUTFP32` | FP32 LUT with linear interpolation | — | 2 cyc | [sfp-lutfp32](isa/tensix_vector/sfp-lutfp32.md) |
| `SFPSWAP` | Lane-wise min+max (simultaneous) | `vminps` | 2 cyc | [vmin](isa/tensix_vector/vmin.md) |
| `SFPSWAP` (max) | Lane-wise max | `vmaxps` | 2 cyc | [vmax](isa/tensix_vector/vmax.md) |
| `SFPMOV` (MAD mode) | VD = -VC | `vxorps` | 1 cyc | [sfp-neg](isa/tensix_vector/sfp-neg.md) |
| `SFPMOV` (ABS) | VD = Abs(VC) | `vandps` | 1 cyc | [sfp-abs](isa/tensix_vector/sfp-abs.md) |
| `SFPABS` | VD = Abs(VC), NaN passthrough | — | 1 cyc | [sfp-abs](isa/tensix_vector/sfp-abs.md) |
| `SFPLUTFP32` | FP32 LUT with 16-entry interpolation | — | 2 cyc | [sfp-lutfp32](isa/tensix_vector/sfp-lutfp32.md) |
| `SFPARECIP` | Approx 1/VC, exp(ABS(VC)), etc. | — | 1 cyc | [sfp-arecip](isa/tensix_vector/sfp-arecip.md) |

### Integer Arithmetic

| Mnemonic | Description | x86 EQ | Lat | Page |
|----------|-------------|--------|:---:|------|
| `SFPIADD` | VD = VC ± VD or VD = VC ± Imm11 | `vpaddd` | 1 cyc | [sfp-iadd](isa/tensix_vector/sfp-iadd.md) |
| `SFPMUL24` | 24-bit signed integer multiply | `vpmuldq` | 2 cyc | [sfp-mul24](isa/tensix_vector/sfp-mul24.md) |
| vavg | Vector average (via SFPIADD + SFPMUL24) | `vpavgw` | 2 cyc | [vavg](isa/tensix_vector/vavg.md) |

### Bitwise / Logical

| Mnemonic | Description | x86 EQ | Lat | Page |
|----------|-------------|--------|:---:|------|
| `SFPAND` | Bitwise AND | `vpand` | 1 cyc | [sfp-and](isa/tensix_vector/sfp-and.md) |
| `SFPOR` | Bitwise OR | `vpor` | 1 cyc | [sfp-or](isa/tensix_vector/sfp-or.md) |
| `SFPXOR` | Bitwise XOR | `vpxor` | 1 cyc | [sfp-xor](isa/tensix_vector/sfp-xor.md) |
| `SFPNOT` | Bitwise NOT | `vpternlog` | 1 cyc | [sfp-not](isa/tensix_vector/sfp-not.md) |

### Comparison / Flags

| Mnemonic | Description | x86 EQ | Lat | Page |
|----------|-------------|--------|:---:|------|
| `SFPGT` | Set lane flags: VD > VC | `vcmpps` GT pred | 1 cyc | [sfp-gt](isa/tensix_vector/sfp-gt.md) |
| `SFPLE` | Set lane flags: VD ≤ VC | `vcmpps` LE pred | 1 cyc | [sfp-le](isa/tensix_vector/sfp-le.md) |
| `SFPLZ` | Set lane flags: VC != 0 / count leading zeros | `lzcnt` (scalar) | 1 cyc | [sfp-lz](isa/tensix_vector/sfp-lz.md) |
| `SFPSETCC` | Set per-lane flags from VC sign/zero | — | 1 cyc | [sfp-setcc](isa/tensix_vector/sfp-setcc.md) |

### Shift / Rotate

| Mnemonic | Description | x86 EQ | Lat | Page |
|----------|-------------|--------|:---:|------|
| `SFPSHFT` | Lane-wise shift left/right/logical | `vpsllw/vpsrlw` | 1 cyc | [vshift](isa/tensix_vector/vshift.md) |
| `SFPSHFT2` | Cross-lane shift, rotate, pack | — | ≤2 cyc | [vshift](isa/tensix_vector/vshift.md) |

### Data Movement (SFPU ↔ Dst)

| Mnemonic | Description | Lat | Page |
|----------|-------------|:---:|------|
| `SFPLOAD` | Load Dst tiles → LReg | 1 cyc | [sfp-load](isa/tensix_vector/sfp-load.md) |
| `SFPSTORE` | Store LReg → Dst tiles | 1 cyc | [sfp-store](isa/tensix_vector/sfp-store.md) |
| `SFPLOADI` | Load immediate (BF16, FP16, int) → LReg | 1 cyc | [sfp-loadi](isa/tensix_vector/sfp-loadi.md) |
| `SFPLOADMACRO` | SFPLOAD + schedule up to 4 extra instructions | cmplx | [sfp-loadmacro](isa/tensix_vector/sfp-loadmacro.md) |
| `SFPMOV` | LReg[VD] = LReg[VC] (register move) | 1 cyc | [sfp-copy](isa/tensix_vector/sfp-copy.md) |
| `SFPTRANSP` | Transpose 4×4 rows within LReg[0:8] | 1 cyc | [sfp-transp](isa/tensix_vector/sfp-transp.md) |

### Type Conversion

| Mnemonic | Description | x86 EQ | Lat | Page |
|----------|-------------|--------|:---:|------|
| `SFPCAST` (IntFloat) | SignMag32 → FP32 | — | 1 cyc | [sfp-cast](isa/tensix_vector/sfp-cast.md) |
| `SFPCAST` (IntInt) | SignMag32 ↔ Int32 | — | 1 cyc | [sfp-cast](isa/tensix_vector/sfp-cast.md) |
| `SFPCAST` (IntAbs) | VD = Abs(VC), int | — | 1 cyc | [sfp-cast](isa/tensix_vector/sfp-cast.md) |
| `SFPSTOCHRND` (FF) | FP32 → BF16/TF32 | `vcvtneps2bf16` | 1 cyc | [vpack](isa/tensix_vector/vpack.md) |
| `SFPSTOCHRND` (FI) | FP32 → INT8/INT16 | — | 1 cyc | [vpack](isa/tensix_vector/vpack.md) |
| `SFPSTOCHRND` (II) | INT32 → INT8/INT16 | `vpackssdw` | 1 cyc | [vpack](isa/tensix_vector/vpack.md) |
| `SFPDIVP2` | VD = VC × 2^Imm8 | `vscalefps` | 1 cyc | [sfp-field](isa/tensix_vector/sfp-field.md) |

### FP Field Manipulation

| Mnemonic | Description | Lat | Page |
|----------|-------------|:---:|------|
| `SFPSETEXP` | Replace exponent field | 1 cyc | [sfp-field](isa/tensix_vector/sfp-field.md) |
| `SFPSETMAN` | Replace mantissa field | 1 cyc | [sfp-field](isa/tensix_vector/sfp-field.md) |
| `SFPSETSGN` | Replace sign field | 1 cyc | [sfp-field](isa/tensix_vector/sfp-field.md) |
| `SFPEXEXP` | Extract exponent | 1 cyc | [sfp-field](isa/tensix_vector/sfp-field.md) |
| `SFPEXMAN` | Extract mantissa | 1 cyc | [sfp-field](isa/tensix_vector/sfp-field.md) |

### Conditional Execution (SIMT Stack)

| Mnemonic | Description | Lat | Page |
|----------|-------------|:---:|------|
| `SFPENCC` | Enable/disable lane predication | 1 cyc | [sfp-pred](isa/tensix_vector/sfp-pred.md) |
| `SFPPUSHC` | Push/mutate flag stack | 1 cyc | [sfp-pred](isa/tensix_vector/sfp-pred.md) |
| `SFPCOMPC` | SIMT `else` mapping | 1 cyc | [sfp-pred](isa/tensix_vector/sfp-pred.md) |
| `SFPPOPC` | Pop flag stack | 1 cyc | [sfp-pred](isa/tensix_vector/sfp-pred.md) |

### Other SFPU

| Mnemonic | Description | Lat | Page |
|----------|-------------|:---:|------|
| `SFPCONFIG` | Set SFPU configuration (rounding, etc.) | ≤2 cyc | [sfp-config](isa/tensix_vector/sfp-config.md) |
| `SFPMOV` (CFG) | VD = CurrentConfiguration | 1 cyc | [sfp-config-read](isa/tensix_vector/sfp-config-read.md) |
| `SFPMOV` (PRNG) | VD = AdvancePRNG() | 1 cyc | [sfp-prng](isa/tensix_vector/sfp-prng.md) |
| `SFPNOP` | No operation | 1 cyc | — |
| vsad | Sum of absolute differences (multi-instruction) | `psadbw` | varies | [vsad](isa/tensix_vector/vsad.md) |
| vunpack | Tile unpack: L1 → Dst with format conversion | `vpmovzx` / `vpmovsx` | 1 cyc | [vunpack](isa/tensix_vector/vunpack.md) |

## Tensix Matrix (FPU) Instructions

| Mnemonic | Description | Page |
|----------|-------------|------|
| `MVMUL` | Matrix-vector/matrix multiply | [mmul](isa/tensix_matrix/mmul.md) |
| `DOTPV` | Dot product of two vectors | [mmadd](isa/tensix_matrix/mmadd.md) |
| `GAPOOL` | Global average pooling | — |
| `GMPOOL` | Global max pooling | — |
| `ZEROACC` | Zero accumulator (Dst) | — |
| `ZEROSRC` | Zero source A/B registers | — |
| `MOV*` | Register-to-register moves within coprocessor | — |
| `XMOV` | Cross-lane data movement | — |
| `TRNSPSRCB` | Transpose source B | — |
| `PACR` / `PACR_SETREG` | Post-accumulation configuration | — |
| `REPLAY` | Replay last MOP iteration | — |

## Data Movement

See [isa/data_movement/](isa/data_movement/).

| Mnemonic | Page |
|----------|------|
| `noc_async_read` | [noc_async_read](isa/data_movement/noc_async_read.md) |
| `noc_async_write` | [noc_async_write](isa/data_movement/noc_async_write.md) |
| `noc_async_write_multicast` | [noc_async_write_multicast](isa/data_movement/noc_async_write_multicast.md) |
| `noc_semaphore_inc` | [noc_semaphore_inc](isa/data_movement/noc_semaphore_inc.md) |
| `noc_semaphore_wait` | [noc_semaphore_wait](isa/data_movement/noc_semaphore_wait.md) |
| `dma_read` | [dma_read](isa/data_movement/dma_read.md) |
| `dma_write` | [dma_write](isa/data_movement/dma_write.md) |
| `LOADIND` | Indirect load from L1 to GPRs | [loadind](isa/data_movement/loadind.md) |
| `LOADREG` | Direct load from L1 to GPRs | [loadreg](isa/data_movement/loadreg.md) |
| `STOREIND` | Indirect store from GPRs to L1 | [storeind](isa/data_movement/storeind.md) |
| `STOREREG` | Direct store from GPRs to L1 | [storereg](isa/data_movement/storereg.md) |
| `SETDMAREG` | Set DMA register (imm/special) | — |
| `ADDDMAREG` | Add to DMA register | — |
| `SUBDMAREG` | Subtract from DMA register | — |
| `MULDMAREG` | Multiply DMA register | — |
| `CMPDMAREG` | Compare DMA register | — |
| `SHIFTDMAREG` | Shift DMA register | — |
| `BITWOPDMAREG` | Bitwise op on DMA register | — |
| `DMANOP` | DMA no-op | — |
| `FLUSHDMA` | Flush pending DMA transactions | — |

## Circular Buffer

See [isa/circular_buffer/](isa/circular_buffer/).

| Mnemonic | Page |
|----------|------|
| `cb_wait_front` | [cb_wait_front](isa/circular_buffer/cb_wait_front.md) |
| `cb_pop_front` | [cb_pop_front](isa/circular_buffer/cb_pop_front.md) |
| `cb_reserve_back` | [cb_push_back](isa/circular_buffer/cb_push_back.md) |
| `cb_push_back` | [cb_push_back](isa/circular_buffer/cb_push_back.md) |
| `get_tile_size` | Tile size query |
| `cb_read` / `cb_write` | Direct CB memory access |

## Scalar Load/Store / Register Move

See [isa/misc/README.md](isa/misc/README.md).

| Mnemonic | Description |
|----------|-------------|
| `LOADIND` | Indirect load: GPR = MEM[Base + Offset × Stride] |
| `LOADREG` | Direct load: GPR = MEM[Addr] |
| `STOREIND` | Indirect store: MEM[Base + Offset × Stride] = GPR |
| `STOREREG` | Direct store: MEM[Addr] = GPR |
| `SETDMAREG` | Load immediate or special value into DMA address register |
| `ADDDMAREG` | DMA[Dest] = DMA[A] + DMA[B] |
| `SUBDMAREG` | DMA[Dest] = DMA[A] - DMA[B] |
| `MULDMAREG` | DMA[Dest] = DMA[A] × DMA[B] |
| `CMPDMAREG` | Compare and set condition flags from DMA registers |
| `SHIFTDMAREG` | Shift DMA register by immediate |
| `BITWOPDMAREG` | Bitwise operation on DMA registers |
| `MOVB2A` / `MOVA2D` / `MOVB2D` / `MOVD2A` / `MOVD2B` / `MOVDBGA2D` | Register moves between A/B/D regs |
| `SETC16` | Write to configuration register C16 |
| `RMWCIB` | Read-modify-write CIB register |
| `SETDVALID` / `CLEARDVALID` | Set/clear data valid flag |
| `GATESRCRST` / `CLREXPHIST` | Source reset / clear exception history |

## Unpacker

See [isa/unpacker/README.md](isa/unpacker/README.md).

| Mnemonic / Operation | Description |
|----------------------|-------------|
| `UNPACR_Regular` | Unpack tile data from L1 → Dst registers with format conversion |
| `UNPACR_FlushCache` | Flush unpacker cache |
| `UNPACR_IncrementContextCounter` | Advance context counter |
| `UNPACR_NOP_Nop` | NOP variant (zero-overhead) |
| `UNPACR_NOP_SETREG` | Set unpacker register |
| `UNPACR_NOP_SETDVALID` | Set DVALID |
| `UNPACR_NOP_ZEROSRC` | Zero source data |
| `UNPACR_NOP_OverlayClear` | Clear overlay data |

## Packer

See [isa/packer/README.md](isa/packer/README.md).

| Operation | Description |
|-----------|-------------|
| Pack tile data from Dst → L1 | Main pack operation |
| `ReLU` | Apply ReLU during pack (zero negative values) |
| `Compression` | Lossless compression of output data |
| `Downsampling` | Reduce spatial resolution during pack |
| `EdgeMasking` | Mask edge tiles |
| `ExponentHistogram` / `ExponentThresholding` | Adaptive exponent management |
| `FormatConversion` | Dst format → output format conversion |
| `InputAddressGenerator` / `OutputAddressGenerator` | Address calculation for tile walks |

## Synchronization

See [isa/synchronization/README.md](isa/synchronization/README.md).

| Mnemonic | Description |
|----------|-------------|
| `STALLWAIT` | Stall until condition met (semaphore, stream) |
| `STREAMWAIT` | Wait for stream data availability |
| `STREAMWRCFG` | Configure stream write parameters |
| `SyncUnit` | Semaphore operations (P, V, try) |
| `SETDVALID` | Mark output data as valid |
| Manual TTSync | Inter-core sync via mailbox |
| Auto TTSync | Hardware-automated sync |

## Atomic Operations

| Mnemonic | Description |
|----------|-------------|
| `ATGETM` | Atomic get (load + reserve) addressed via `ADDRCRXY/ZW` |
| `ATRELM` | Atomic release (store) matched to `ATGETM` |
| `ATCAS` | Atomic compare-and-swap |
| `ATSWAP` | Atomic swap |
| `ATINCGET` | Atomic increment-and-get |
| `ATINCGETPTR` | Atomic increment pointer-and-get |
| `RMWCIB` | Read-modify-write CIB register |

## Semaphore Operations

| Mnemonic | Description |
|----------|-------------|
| `SEMGET` | Read semaphore value |
| `SEMINIT` | Initialize semaphore |
| `SEMPOST` | Increment semaphore (V operation) |
| `SEMWAIT` | Decrement and wait semaphore (P operation) |

## Configuration

See [isa/configuration/README.md](isa/configuration/README.md).

| Mnemonic | Description |
|----------|-------------|
| `WRCFG` | Write to coprocessor configuration register |
| `RDCFG` | Read from coprocessor configuration register |
| `CFGSHIFTMASK` | Generate shift mask for config address |
| `SFPCONFIG` | SFPU configuration (rounding mode, PRNG seed, LUT base) |
| `BackendConfiguration` | Tensix backend pipeline config (matrix engine settings, etc.) |
| `ConfigurationUnit` | Configuration register space overview |

## MOP Expander

| Mnemonic | Description |
|----------|-------------|
| `MOP` | Macro-Operation: loop/repeat a sequence of Tensix coprocessor instructions |
| `MOP_CFG` | Configure MOP parameters (loop count, stride, etc.) |
| `REPLAY` | Replay last MOP iteration (debug) |

## Other / Utility

| Mnemonic | Description |
|----------|-------------|
| `NOP` | No operation (frontend) |
| `REPLAY` | Replay last coprocessor instruction |
| `REG2FLOP_ADC` | Register-to-flop with ADC semantics |
| `REG2FLOP_Configuration` | Register-to-flop configuration |
| `XMOV` | Cross-lane data movement in Dst |
