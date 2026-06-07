# `noc_semaphore_inc` – NoC Semaphore Increment

**Category:** Synchronization (NoC Atomic)

**Syntax:** `noc_semaphore_inc(noc_addr, delta)`

**Operation:** Atomically increment a 32-bit semaphore value at a remote NoC address. The target address must be 128-bit aligned in L1.

**x86 Equivalent:** `lock add` / `atomic_fetch_add`

**Latency:** ~25-40 cycles (to DRAM), ~19+ (to adjacent core)

**Notes:**
- Target must be 128-bit aligned in L1
- Used for inter-core producer-consumer synchronization
- Can optionally be posted (no response)
- Can optionally be broadcast to a rectangle of Tensix tiles
