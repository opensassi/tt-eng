# `noc_async_write_multicast` – NoC Multicast Write

**Category:** Data Movement (NoC)

**Syntax:** `noc_async_write_multicast(local_l1_addr, dest_rect, size)`

**Operation:** Broadcast write to a rectangular group of Tensix tiles. Receivers must be Tensix tiles (not DRAM or Ethernet).

**x86 Equivalent:** No direct equivalent

**Notes:**
- Receivers can only be Tensix tiles
- Path reservation (`NOC_CMD_PATH_RESERVE`) can improve latency at the cost of setup time
- Without path reservation, deadlock avoidance becomes software's responsibility
- Broadcast uses virtual channel class `0b10`
