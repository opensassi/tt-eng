# `noc_async_write_multicast` – NoC Multicast Write

**Category:** Data Movement (NoC)

**Syntax:** `noc_async_write_multicast(local_l1_addr, dest_rect, size)`

**Operands:**
- `local_l1_addr`: Source L1 address on the initiating Tensix tile.
- `dest_rect`: Target rectangle encoded as `{x_start, y_start, x_end, y_end}` with 6-bit coordinates per dimension. Written to the `NOC_TARG_ADDR_HI` broadcast fields. Wraparound occurs when Start > End.
- `size`: Number of bytes to write.

**Operation:** Broadcast write to a rectangular group of Tensix tiles. Receivers must be Tensix tiles (not DRAM or Ethernet).

**Latency:** ~25–45 cycles (adjacent rectangle) to ~250 cycles (cross-chip, path-reserved). Baseline unicast write latency is ~19 cycles (adjacent) to ~200 cycles (cross-chip); multicast adds packet replication overhead and optional path reservation setup time.

**x86 Equivalent:** No direct equivalent

**Notes:**
- Receivers can only be Tensix tiles
- Path reservation (`NOC_CMD_PATH_RESERVE`) can improve latency at the cost of setup time
- Without path reservation, deadlock avoidance becomes software's responsibility
- Broadcast uses virtual channel class `0b10`

**Errata:**
- **Blackhole:** `NOC_CMD_WR_INLINE` must not be used when the destination is an L1 address (hardware bug). Multicast writes must always use non-inline mode.

**Blackhole vs Wormhole Differences:**
- Multicast behavior is consistent between Wormhole and Blackhole.
- Coordinate translation differs: Wormhole writes translated coordinates back to `NOC_TARG_ADDR_HI` (MMIO readable); Blackhole does not writeback translated coordinates.

**Example:**
```c
noc_async_write_multicast(l1_addr, {x_start, y_start, x_end, y_end}, size);
noc_async_write_barrier();
