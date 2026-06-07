# `noc_async_write` – NoC Asynchronous Write

**Category:** Data Movement (NoC)

**Syntax:** `noc_async_write(local_l1_addr, dest_noc_addr, size)`

**Operation:** Initiate an asynchronous write from local L1 to a remote NoC address. Returns immediately; completion checked via `noc_async_write_barrier()`.

**x86 Equivalent:** No direct equivalent; similar to RDMA write

**Latency:** ~19 cycles (adjacent core) to ~200 cycles (cross-chip)

**Notes:**
- Posted writes (no acknowledgement) for performance
- Non-posted writes available for ordering guarantees
- In Blackhole, `NOC_CMD_WR_INLINE` can no longer be safely used for L1 writes
- Stores coalesced in the local store queue before NoC transmission
