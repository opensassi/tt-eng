# RV32IM Base Instruction Set

The Baby RISC-V cores implement the standard RV32IM instruction set (32-bit base integer + multiply/divide extension). Only non-obvious deviations from the RISC-V specification are documented here.

## Core Comparison

5 cores with different capabilities: B (branch), N (NoC), C (compute), NC (NoC+compute), E (eth). Pipeline stages: EX1/EX2/EX3.

## Standard RV32IM

All standard RV32I instructions are implemented as specified in Version 2.1:
- `lw`, `lh`, `lb`, `lbu`, `lhu` — loads
- `sw`, `sh`, `sb` — stores
- `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and` — ALU
- `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai` — immediate ALU
- `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` — branches
- `jal`, `jalr` — jumps
- `lui`, `auipc` — address formation

## M Extension

Standard multiply/divide: `mul`, `mulh`, `mulhsu`, `mulhu`, `div`, `divu`, `rem`, `remu`.

Divide latency: 2-33 cycles depending on operand magnitude. Divide by 0 or 1: 2 cycles.

## Zicsr Extension

CSR access for control/status registers.

## Zaamo Extension

amoadd.w etc. — local L1 only, not MMIO; always aq+rl.

## Zba Extension

sh1add, sh2add, sh3add.

## Zbb Extension

andn, clz, cpop, ctz, max, min, orcb, rev8, sext.b, sext.h, zext.h.

## F Extension (Single-Precision Float)

RNE only. Denormals flushed to zero. No fdiv.s/fsqrt.s. Non-IEEE754 FMA.

## Zfh Extension (Half-Precision Float)

BF16 mode via CSR bit.

## V Extension (Vector)

T2 only (16-byte vectors). Known false-dependency bug on destination. Fractional LMUL bug.

## Non-Standard Behavior

- `ebreak`: Triggers a debug pause (not a trap)
- `fence`: Always executed with strongest ordering, BUT device output is NOT covered by this ordering. Use fence.i for instruction synchronization.
- `mret`: Available only on RISCV B and NC (interrupt return)

## WH vs BH Differences

| Feature | Wormhole (WH) | Blackhole (BH) |
|---------|---------------|-----------------|
| Clock | 1.0 GHz | 1.35 GHz |
| L1 | 1464 KB | 1536 KB |
| Local RAM | 4KB/2KB | 8KB/4KB |
| fence | NOP (not implemented) | Strongest ordering |
| F/Zfh/V | Not available | Available |
| Pipeline | Differs | Differs |
