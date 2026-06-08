# RV32IM Base Instruction Set

The Baby RISC-V cores implement the standard RV32IM instruction set (32-bit base integer + multiply/divide extension). Only non-obvious deviations from the RISC-V specification are documented here.

Instructions execute on the Baby RISC-V cores themselves — not on the Tensix backend execution units (Sync, Unpackers, Matrix, Packers, Vector, Scalar, Config, Mover, Misc). The cores interface with the Tensix coprocessor by pushing Tensix instructions (UNPACR, PACR, etc.) via stores to a special memory-mapped address region; those pushed instructions then execute on the backend. All RV32IM instructions documented here run directly on the RISC-V pipeline.

## Core Comparison

5 cores with different capabilities: B (branch), N (NoC), C (compute), NC (NoC+compute), E (eth). Pipeline stages: EX1/EX2/EX3.

---

## Register File

| Register | ABI Name | Saver | Description |
|----------|----------|-------|-------------|
| x0       | zero     | —     | Hardwired zero |
| x1       | ra       | Caller | Return address |
| x2       | sp       | Callee | Stack pointer |
| x3       | gp       | —     | Global pointer |
| x4       | tp       | —     | Thread pointer |
| x5–x7    | t0–t2    | Caller | Temporaries |
| x8       | s0/fp    | Callee | Saved / frame pointer |
| x9       | s1       | Callee | Saved register |
| x10–x11  | a0–a1    | Caller | Function args / return |
| x12–x17  | a2–a7    | Caller | Function args |
| x18–x27  | s2–s11   | Callee | Saved registers |
| x28–x31  | t3–t6    | Caller | Temporaries |

All 32 registers (x0–x31) are present in every Baby RISC-V core. x0 always reads zero; writes to x0 are discarded.

---

## Standard RV32I

All standard RV32I instructions are implemented as specified in Version 2.1. Each instruction is 32 bits, and all execute in a single cycle except loads (2–3 cycles), branches (variable), and CSR/mret.

### Loads

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `lb`     | `lb rd, offset(rs1)` | Load byte, sign-extend |
| `lh`     | `lh rd, offset(rs1)` | Load halfword, sign-extend |
| `lw`     | `lw rd, offset(rs1)` | Load word, sign-extend |
| `lbu`    | `lbu rd, offset(rs1)` | Load byte, zero-extend |
| `lhu`    | `lhu rd, offset(rs1)` | Load halfword, zero-extend |

**Latency**: 2 cycles (L1 hit), ≥3 cycles (NoC access).  
**Precondition**: `offset(rs1)` must be naturally aligned for `lw` (word-aligned). Misaligned access raises a trap.  
**Example**: `lw t0, 0(sp)` — load word from address sp+0 into t0.

### Stores

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `sb`     | `sb rs2, offset(rs1)` | Store byte |
| `sh`     | `sh rs2, offset(rs1)` | Store halfword |
| `sw`     | `sw rs2, offset(rs1)` | Store word |

**Latency**: 1 cycle (write to L1), not visible to software until a following `fence` or CSR read.  
**Example**: `sw a0, 0(sp)` — store a0 to address sp+0.

### ALU Register

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `add`    | `add rd, rs1, rs2` | rd = rs1 + rs2 |
| `sub`    | `sub rd, rs1, rs2` | rd = rs1 - rs2 |
| `sll`    | `sll rd, rs1, rs2` | rd = rs1 << rs2[4:0] |
| `slt`    | `slt rd, rs1, rs2` | rd = (rs1 < rs2) signed |
| `sltu`   | `sltu rd, rs1, rs2` | rd = (rs1 < rs2) unsigned |
| `xor`    | `xor rd, rs1, rs2` | rd = rs1 ^ rs2 |
| `srl`    | `srl rd, rs1, rs2` | rd = rs1 >> rs2[4:0] (logical) |
| `sra`    | `sra rd, rs1, rs2` | rd = rs1 >> rs2[4:0] (arithmetic) |
| `or`     | `or rd, rs1, rs2` | rd = rs1 \| rs2 |
| `and`    | `and rd, rs1, rs2` | rd = rs1 & rs2 |

**Latency**: 1 cycle.  
**Example**: `add t1, t0, a0` — t1 = t0 + a0.

### ALU Immediate

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `addi`   | `addi rd, rs1, imm12` | rd = rs1 + SignExt(imm12) |
| `slti`   | `slti rd, rs1, imm12` | rd = (rs1 < SignExt(imm12)) signed |
| `sltiu`  | `sltiu rd, rs1, imm12` | rd = (rs1 < SignExt(imm12)) unsigned |
| `xori`   | `xori rd, rs1, imm12` | rd = rs1 ^ SignExt(imm12) |
| `ori`    | `ori rd, rs1, imm12` | rd = rs1 \| SignExt(imm12) |
| `andi`   | `andi rd, rs1, imm12` | rd = rs1 & SignExt(imm12) |
| `slli`   | `slli rd, rs1, shamt5` | rd = rs1 << shamt5 |
| `srli`   | `srli rd, rs1, shamt5` | rd = rs1 >> shamt5 (logical) |
| `srai`   | `srai rd, rs1, shamt5` | rd = rs1 >> shamt5 (arithmetic) |

**Latency**: 1 cycle.  
**Example**: `addi sp, sp, -16` — allocate 16 bytes on stack.

### Branches

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `beq`    | `beq rs1, rs2, offset` | Branch == |
| `bne`    | `bne rs1, rs2, offset` | Branch != |
| `blt`    | `blt rs1, rs2, offset` | Branch < (signed) |
| `bge`    | `bge rs1, rs2, offset` | Branch ≥ (signed) |
| `bltu`   | `bltu rs1, rs2, offset` | Branch < (unsigned) |
| `bgeu`   | `bgeu rs1, rs2, offset` | Branch ≥ (unsigned) |

**Latency**: Not-taken: 1 cycle. Taken: 2 cycles (branch misprediction penalty: 1 cycle flushed).  
**Example**: `beq a0, zero, exit` — jump to `exit` if a0 == 0.

### Jumps

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `jal`    | `jal rd, offset` | Jump and link (PC-relative, 21-bit signed offset) |
| `jalr`   | `jalr rd, rs1, offset` | Jump and link (register + imm12) |

**Latency**: 2 cycles (includes return-address write + pipeline refill).  
**Example**: `jal ra, func` — call `func`, return address in ra.

### Address Formation

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `lui`    | `lui rd, imm20` | rd = imm20 << 12 |
| `auipc`  | `auipc rd, imm20` | rd = PC + (imm20 << 12) |

**Latency**: 1 cycle.  
**Example**: `lui t0, 0x10000` — t0 = 0x10000000.

---

## M Extension (Multiply/Divide)

### Multiply

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `mul`    | `mul rd, rs1, rs2` | rd = (rs1 * rs2)[31:0] |
| `mulh`   | `mulh rd, rs1, rs2` | rd = ((rs1 * rs2) >> 32) signed×signed |
| `mulhsu` | `mulhsu rd, rs1, rs2` | rd = ((rs1 * rs2) >> 32) signed×unsigned |
| `mulhu`  | `mulhu rd, rs1, rs2` | rd = ((rs1 * rs2) >> 32) unsigned×unsigned |

**Latency**: 4 cycles (all multiply variants). Pipelined: a new multiply can start every 2 cycles.  
**Example**: `mul t0, a0, a1` — low 32 bits of a0*a1 into t0.

### Divide/Remainder

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `div`    | `div rd, rs1, rs2` | Signed quotient |
| `divu`   | `divu rd, rs1, rs2` | Unsigned quotient |
| `rem`    | `rem rd, rs1, rs2` | Signed remainder |
| `remu`   | `remu rd, rs1, rs2` | Unsigned remainder |

**Latency**: 2–33 cycles depending on operand magnitude. Divide by 0 or ±1: 2 cycles.  
**Undefined behavior**: divide overflow (rs1 = 0x80000000, rs2 = 0xFFFFFFFF with `div`) produces rs1 (not a trap).  
**Example**: `div t0, a0, a1` — a0 ÷ a1, signed.

---

## Zicsr Extension

CSR access for control/status registers. 12-bit CSR address space.

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `csrrw`  | `csrrw rd, csr, rs1` | Atomic read-write |
| `csrrs`  | `csrrs rd, csr, rs1` | Atomic read-set (rd = CSR, CSR |= rs1) |
| `csrrc`  | `csrrc rd, csr, rs1` | Atomic read-clear (rd = CSR, CSR &= ~rs1) |
| `csrrwi` | `csrrwi rd, csr, uimm5` | Read-write immediate |
| `csrrsi` | `csrrsi rd, csr, uimm5` | Read-set immediate |
| `csrrci` | `csrrci rd, csr, uimm5` | Read-clear immediate |

**Latency**: 2 cycles (serializes pipeline).  
**Precondition**: Privilege level must permit access (machine-mode CSR accessible only in M-mode).  
**Example**: `csrr t0, mcycle` — read cycle counter into t0.

---

## Zaamo Extension

Atomic memory operations on L1 only (not MMIO). Always issued with `aq` (acquire) and `rl` (release) semantics.

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `amoadd.w` | `amoadd.w rd, rs2, (rs1)` | Atomic add |
| `amoswap.w` | `amoswap.w rd, rs2, (rs1)` | Atomic swap |
| `amoand.w` | `amoand.w rd, rs2, (rs1)` | Atomic AND |
| `amoor.w` | `amoor.w rd, rs2, (rs1)` | Atomic OR |
| `amoxor.w` | `amoxor.w rd, rs2, (rs1)` | Atomic XOR |
| `amomax.w` | `amomax.w rd, rs2, (rs1)` | Atomic signed max |
| `amomaxu.w` | `amomaxu.w rd, rs2, (rs1)` | Atomic unsigned max |
| `amomin.w` | `amomin.w rd, rs2, (rs1)` | Atomic signed min |
| `amominu.w` | `amominu.w rd, rs2, (rs1)` | Atomic unsigned min |

**Latency**: 3–5 cycles (depends on L1 bank contention).  
**Restriction**: Target address must be in local L1; accessing MMIO via Zaamo is unsupported and produces undefined results.  
**Example**: `amoadd.w t0, a0, (sp)` — atomically add a0 to *(sp), return old value in t0.

---

## Zba Extension (Address Generation)

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `sh1add` | `sh1add rd, rs1, rs2` | rd = (rs1 << 1) + rs2 |
| `sh2add` | `sh2add rd, rs1, rs2` | rd = (rs1 << 2) + rs2 |
| `sh3add` | `sh3add rd, rs1, rs2` | rd = (rs1 << 3) + rs2 |

**Latency**: 1 cycle.  
**Example**: `sh2add t0, a0, sp` — t0 = a0*4 + sp.

---

## Zbb Extension (Bit Manipulation)

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `andn`   | `andn rd, rs1, rs2` | rd = rs1 & ~rs2 |
| `clz`    | `clz rd, rs1` | Count leading zeros |
| `cpop`   | `cpop rd, rs1` | Count set bits (population count) |
| `ctz`    | `ctz rd, rs1` | Count trailing zeros |
| `max`    | `max rd, rs1, rs2` | Signed maximum |
| `min`    | `min rd, rs1, rs2` | Signed minimum |
| `orcb`   | `orcb rd, rs1` | Bitwise OR-combine across bytes |
| `rev8`   | `rev8 rd, rs1` | Byte-reverse (within 32-bit word) |
| `sext.b` | `sext.b rd, rs1` | Sign-extend byte |
| `sext.h` | `sext.h rd, rs1` | Sign-extend halfword |
| `zext.h` | `zext.h rd, rs1` | Zero-extend halfword |

**Latency**: 1 cycle (`clz`, `cpop`, `ctz` are combinational; the rest are 1-cycle ALU).  
**Example**: `clz t0, a0` — count leading zeros of a0, result in t0.

---

## F Extension (Single-Precision Float)

Rounding mode: RNE only (round-to-nearest-even). Denormals flushed to zero. No `fdiv.s` or `fsqrt.s` — these produce an illegal-instruction trap. Non-IEEE754 FMA (slightly reduced precision).

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `flw`    | `flw rd, offset(rs1)` | Load float (32-bit) |
| `fsw`    | `fsw rs2, offset(rs1)` | Store float (32-bit) |
| `fadd.s` | `fadd.s rd, rs1, rs2` | rd = rs1 + rs2 |
| `fsub.s` | `fsub.s rd, rs1, rs2` | rd = rs1 - rs2 |
| `fmul.s` | `fmul.s rd, rs1, rs2` | rd = rs1 * rs2 |
| `fdiv.s` | — | Not implemented (trap) |
| `fsqrt.s`| — | Not implemented (trap) |
| `fmadd.s`| `fmadd.s rd, rs1, rs2, rs3` | rd = rs1*rs2 + rs3 (FMA) |
| `fmsub.s`| `fmsub.s rd, rs1, rs2, rs3` | rd = rs1*rs2 - rs3 |
| `fnmadd.s`| `fnmadd.s rd, rs1, rs2, rs3` | rd = -(rs1*rs2) - rs3 |
| `fnmsub.s`| `fnmsub.s rd, rs1, rs2, rs3` | rd = -(rs1*rs2) + rs3 |
| `feq.s`  | `feq.s rd, rs1, rs2` | rd = (rs1 == rs2) |
| `flt.s`  | `flt.s rd, rs1, rs2` | rd = (rs1 < rs2) |
| `fle.s`  | `fle.s rd, rs1, rs2` | rd = (rs1 ≤ rs2) |
| `fmin.s` | `fmin.s rd, rs1, rs2` | rd = min(rs1, rs2) |
| `fmax.s` | `fmax.s rd, rs1, rs2` | rd = max(rs1, rs2) |
| `fcvt.w.s` | `fcvt.w.s rd, rs1` | Convert float to signed int |
| `fcvt.wu.s`| `fcvt.wu.s rd, rs1` | Convert float to unsigned int |
| `fcvt.s.w` | `fcvt.s.w rd, rs1` | Convert signed int to float |
| `fcvt.s.wu`| `fcvt.s.wu rd, rs1` | Convert unsigned int to float |
| `fsgnj.s` | `fsgnj.s rd, rs1, rs2` | rd[31] = rs2[31], rd[30:0] = rs1[30:0] |
| `fsgnjn.s`| `fsgnjn.s rd, rs1, rs2` | rd[31] = ~rs2[31], rd[30:0] = rs1[30:0] |
| `fsgnjx.s`| `fsgnjx.s rd, rs1, rs2` | rd[31] = rs1[31] ^ rs2[31], rd[30:0] = rs1[30:0] |

**Latency**: `flw` 2 cycles; `fsw` 1 cycle; `fadd.s`/`fsub.s` 4 cycles; `fmul.s` 4 cycles; FMA 5 cycles; compare/convert 2 cycles.  
**Precondition**: `fcsr` CSR must be configured for RNE rounding (default). FP register file (f0–f31) is 32 × 32-bit.  
**Example**: `flw ft0, 0(a0)` — load float from *(a0) into ft0; `fadd.s ft0, ft0, ft1` — ft0 += ft1.

---

## Zfh Extension (Half-Precision Float)

Half-precision floating-point via the same FP register file. Use BF16 mode by setting the BF16 bit in a dedicated CSR (core-specific; see core documentation).

When BF16 mode is disabled, standard IEEE half-precision (binary16) with RNE rounding and denormals-flushed-to-zero applies. When BF16 mode is enabled, all Zfh operations behave as BF16 (bfloat16).

| Mnemonic | Syntax | Description |
|----------|--------|-------------|
| `flh`    | `flh rd, offset(rs1)` | Load half (16-bit) |
| `fsh`    | `fsh rs2, offset(rs1)` | Store half (16-bit) |
| `fadd.h` | `fadd.h rd, rs1, rs2` | Half-precision add |
| `fsub.h` | `fsub.h rd, rs1, rs2` | Half-precision sub |
| `fmul.h` | `fmul.h rd, rs1, rs2` | Half-precision mul |
| `fmadd.h`| `fmadd.h rd, rs1, rs2, rs3` | Half-precision FMA |
| `fmsub.h`| `fmsub.h rd, rs1, rs2, rs3` | Half-precision FMA |
| `feq.h`  | `feq.h rd, rs1, rs2` | Compare == |
| `flt.h`  | `flt.h rd, rs1, rs2` | Compare < |
| `fle.h`  | `fle.h rd, rs1, rs2` | Compare ≤ |
| `fcvt.s.h`| `fcvt.s.h rd, rs1` | Convert half to single |
| `fcvt.h.s`| `fcvt.h.s rd, rs1` | Convert single to half |

**Latency**: Same as corresponding F-extension operations (half precision uses same FP pipeline stage).  
**Precondition**: Zfh extension must be enabled in `misa` or core-specific CSR. BF16 mode set via CSR bit.  
**Example**: `flh ft0, 0(a0)` — load half; `fcvt.s.h ft0, ft0` — convert to single precision.

---

## V Extension (Vector)

T2 thread only (16-byte vectors, i.e., `VLEN = 128`). Only LMUL=1, LMUL=2, LMUL=4, LMUL=8 fractional LMUL values are supported; fractional LMUL (LMUL < 1) has a known bug (see below).

| Mnemonic Category | Description |
|-------------------|-------------|
| `vsetvli` / `vsetivli` / `vsetvl` | Vector length / configuration |
| `vle8.v` / `vle16.v` / `vle32.v` | Vector load |
| `vse8.v` / `vse16.v` / `vse32.v` | Vector store |
| `vadd.vv` / `vadd.vx` / `vadd.vi` | Vector add |
| `vsub.vv` / `vsub.vx` | Vector sub |
| `vmul.vv` / `vmul.vx` | Vector multiply |
| `vdiv.vv` / `vdiv.vx` | Vector divide |
| `vfmul.vv` / `vfadd.vv` etc. | Vector FP operations |

**Precondition**: `vtype` CSR must be configured before any vector operation. `vl` CSR set by `vsetvli`.  
**Known bug — false dependency on destination**: A vector instruction whose destination register matches a prior instruction's destination (even if that prior instruction wrote a different vector register) may stall incorrectly. Workaround: insert a `vxor.vi vd, vd, 0` or use a fresh destination register.  
**Known bug — fractional LMUL**: LMUL < 1 (e.g., LMUL=1/2, 1/4, 1/8) may produce incorrect results for certain element widths. Workaround: use LMUL ≥ 1 and software masking.  
**Latency**: Dependent on element count and operation; typically 1 cycle per element group for arithmetic, variable for loads/stores.  
**Example**: `vsetvli t0, a0, e32, m1` — set VLEN=128, 32-bit elements, LMUL=1; `vle32.v v0, (a1)` — load 4 words into v0.

---

## Non-Standard Behavior

- `ebreak`: Triggers a debug pause (not a trap). Execution halts until the debugger resumes the core. No trap handler invoked.
- `fence`: Always executed with strongest ordering on cores where implemented, BUT device output is NOT covered by this ordering. Use `fence.i` for instruction-stream synchronization.
- `mret`: Available only on RISCV B and NC (interrupt return). On other cores, `mret` produces an illegal-instruction trap.

### fence per Core

| Core | fence behavior |
|------|----------------|
| B, N, C, NC, E | `fence` enforces strongest ordering for all memory operations (load/store) |
| WH only | `fence` is a NOP (not implemented) |

Use `fence.i` on all cores for instruction-fetch ordering.

---

## Pipeline Scheduling & Hazards

The Baby RISC-V cores have a 3-stage pipeline (EX1/EX2/EX3).

### Forwarding

- ALU → ALU: full forwarding from EX2 to EX1 (no stall).
- Load → ALU: 1-cycle stall (result ready at end of EX2, not usable in next EX1).
- Branch condition computed in EX2: 1-cycle penalty on taken branches.

### Hazards

| Hazard Type | Detection | Resolution |
|-------------|-----------|------------|
| RAW (load-use) | rs1/rs2 == load rd in preceding insn | 1-cycle interlock (stall) |
| RAW (ALU) | rs1/rs2 == ALU rd in preceding insn | Forwarded (0 stalls) |
| Control (branch) | Taken branch | 1-cycle flush |
| CSR read-after-write | CSR hazard in adjacent insns | 1-cycle stall |
| Multiply (M) response | `mul` → `add` using result | 3-cycle stall (multiply not fully pipelined for result forwarding) |
| Divide response | `div` → use | Full divide latency (2–33 cycles), not forwarded |

### Branch Misprediction

All cores use static branch prediction (not-taken). Mispredicted taken branches incur a 1-cycle penalty. There is no BTB or return-address stack.

### Multi-Cycle Instructions

| Instruction | Latency | Interlock |
|-------------|---------|-----------|
| ALU (add, sub, logical, shift) | 1 cycle | None |
| Load (L1 hit) | 2 cycles | 1-cycle stall if consumed immediately |
| Store | 1 cycle | None (posted write) |
| Branch (not-taken) | 1 cycle | None |
| Branch (taken) | 2 cycles | 1-cycle penalty |
| `mul` / `mulh` / `mulhsu` / `mulhu` | 4 cycles | 3-cycle stall on result use |
| `div` / `divu` / `rem` / `remu` | 2–33 cycles | Full latency (not forwarded) |
| CSR r/w | 2 cycles | 1-cycle stall on dependent CSR read |
| `fence` | ~2 cycles | Serializes pipeline |
| `ebreak` | Variable | Halts until debugger resumes |

### IPC Expectations

Average IPC on in-order 3-stage core with forwarding: ~0.7–0.9 on well-scheduled code (avoiding load-use and multiply stalls).

---

## WH vs BH Differences

| Feature | Wormhole (WH) | Blackhole (BH) |
|---------|---------------|-----------------|
| Clock | 1.0 GHz | 1.35 GHz |
| L1 | 1464 KB | 1536 KB |
| Local RAM | 4KB/2KB | 8KB/4KB |
| `fence` | NOP (not implemented) | Strongest ordering |
| F/Zfh/V | Not available | Available |
| Pipeline | Differs | Differs |
| Branch penalty | 2 cycles (not-taken predicted) | 1 cycle (not-taken predicted) |
| Multiply latency | 5 cycles | 4 cycles |

Note: F/Zfh/V extensions are only present on Blackhole cores. Wormhole cores trap on any F/Zfh/V instruction.

---

## Configuration Requirements

### CSR Setup for FP Operations

```asm
# Set rounding mode to RNE (default after reset)
csrwi fcsr, 0

# Zfh BF16 mode (BH only) — set core-specific CSR bit
# See per-core documentation for the exact CSR address
li t0, 1
csrw <bf16_csr>, t0
