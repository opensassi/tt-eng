# `noc_async_write` – NoC Asynchronous Write

**Category:** Data Movement (NoC)

**Syntax:** `noc_async_write(local_l1_addr, dest_noc_addr, size)`

**Parameters:**
- `local_l1_addr` (`uint32_t`) — Source L1 memory address (must be 16-byte aligned for optimal performance, 4-byte aligned minimum).
- `dest_noc_addr` (`uint32_t`) — Encoded destination NoC address: `(noc_id << 32) | (core_x << 24) | (core_y << 16) | l1_offset`. Must be 16-byte aligned.
- `size` (`uint32_t`) — Number of bytes to transfer (must be a multiple of 4; max 4096 bytes per transaction).

**Operation:** Initiate an asynchronous write from local L1 to a remote NoC address. Returns immediately; completion checked via `noc_async_write_barrier()`.

**x86 Equivalent:** No direct equivalent; similar to RDMA write

**Latency:** ~19 cycles (adjacent core) to ~200 cycles (cross-chip)

**Throughput:** Up to ~32 GB/s for 4 KB transfers on NOC_0; smaller transfers see reduced effective bandwidth due to header overhead (e.g., ~8 GB/s at 64 bytes). Latency increases with NoC hop count and congestion.

## Example

```c
// Allocate source buffer in local L1 (16-byte aligned)
uint32_t src_addr = l1_malloc(1024);
for (int i = 0; i < 256; i++)
    ((uint32_t *)src_addr)[i] = i;

// Encode destination: NOC 0, core (1,1), L1 offset 0x10000
uint32_t dest_noc_addr = NOC_XY_ENCODING(1, 1) | 0x10000;

// Issue asynchronous write (256 bytes)
noc_async_write(src_addr, dest_noc_addr, 256);

// Wait for completion
noc_async_write_barrier();

// dest_noc_addr now contains the 256-byte payload
