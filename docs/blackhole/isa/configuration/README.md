# Configuration Instructions

## `RDCFG` – Read Configuration

**Syntax:** `RDCFG ResultReg, CfgIndex`

**Backend execution unit:** Configuration Unit

Read 32 bits from Config bank selected by `CFG_STATE_ID` into a Tensix GPR (`GPRs[CurrentThread][ResultReg]`). Cannot read ThreadConfig.

**Register constraints:**
- `ResultReg`: u6 (GPR index 0–63)
- `CfgIndex`: bounded by `CFG_STATE_SIZE * 4`

**Scheduling:** ≥2 cycles, fully pipelined (IPC 1), issuing thread not blocked. Additional cycles if GPR write contention.

**Restrictions:**
- Do not consume the GPR result of `RDCFG` in the immediately following instruction(s).
- Use `STALLWAIT` after multiple `RDCFG` instructions due to GPR write contention.

**Example:**
```c
TT_RDCFG(/* ResultReg */ 12, /* CfgIndex */ 0x1A);
