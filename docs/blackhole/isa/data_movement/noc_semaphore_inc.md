# `noc_semaphore_inc` – NoC Semaphore Increment

**Category:** Synchronization (NoC Atomic)

**Syntax:** `noc_semaphore_inc(noc_addr, delta[, IntWidth])`

**IntWidth parameter:** Controls how many bits participate in the masked increment. Setting `IntWidth` to 31 (default) performs a full 32-bit increment. Setting it to a smaller value increments only the low `IntWidth+1` bits; higher bits remain unchanged.

**Operation:** Atomically increment a 32-bit semaphore value at a remote NoC address using a masked-add: only the low `IntWidth+1` bits of the target are modified; higher bits are preserved.

The effective mask is `IntMask = (2u << IntWidth) - 1u`. The operation performed is:
`*L1Address = ((*L1Address + delta) & IntMask) | (*L1Address & ~IntMask);`

The target address must be 128-bit aligned in L1 of a Tensix or Ethernet tile.

**x86 Equivalent:** `lock add` / `atomic_fetch_add`

**Latency:** ~25-40 cycles (to remote L1), ~19+ (to adjacent core)

**Valid target addresses:** L1 of Tensix tiles or Ethernet tiles only. Atomic operations cannot be performed against DRAM addresses or MMIO addresses.

**Notes:**
- Target must be 128-bit aligned in L1
- The `Ofs` field selects which 32-bit word within the 16-byte aligned block to target
- Used for inter-core producer-consumer synchronization
- Can optionally be posted (no response) — posted mode is the default when `NOC_CMD_RESP_MARKED = 0`; a non-posted (marked) request writes the original value back to `NOC_RET_ADDR`
- Can optionally be broadcast to a rectangle of Tensix tiles

**Configuration Requirements:**

Before calling `noc_semaphore_inc`, the following NOC registers must be configured:

| Register | Purpose |
|----------|---------|
| `NOC_AT_LEN_BE` | Sets `IntWidth` (bit-width of masked increment) |
| `NOC_AT_DATA` | Holds the delta value to add |
| `NOC_TARG_ADDR` | Target L1 address (128-bit aligned) |
| `NOC_CMD_RESP_MARKED` | Set to 0 for posted mode (default), 1 for marked (response) mode |

**Blackhole vs Wormhole Note:**

On Blackhole (BH) the target address high register is `NOC_TARG_ADDR_HI`; on Wormhole (WH) it is `NOC_TARG_ADDR_MID`. The TT-Metalium API abstracts this difference away.

**Example:**

```cpp
// TT-Metalium API usage (defaults to IntWidth=31, full 32-bit increment)
uint32_t noc_addr = l1_address | (uint32_t)(core_x << NOC_X_SHIFT) | (uint32_t)(core_y << NOC_Y_SHIFT);
uint32_t delta = 1;
noc_semaphore_inc(noc_addr, delta);

// Low-level register setup for masked 8-bit increment (IntWidth=7):
// NOC_AT_LEN_BE.IntWidth = 7;
// NOC_AT_DATA = 1;
// NOC_TARG_ADDR = <128-bit-aligned L1 address>;
// NOC_CMD_RESP_MARKED = 0;  // posted mode
