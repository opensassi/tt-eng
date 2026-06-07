# `noc_async_read` – NoC Asynchronous Read

**Category:** Data Movement (NoC)

**Syntax:** `noc_async_read(source_noc_addr, local_l1_addr, size)`

**Operation:** Initiate an asynchronous read from a remote NoC address into local L1 memory. Returns immediately; completion checked via `noc_async_read_barrier()`.

**x86 Equivalent:** No direct equivalent; similar to RDMA read

**Latency:** ~19 cycles (adjacent core) to ~200 cycles (cross-chip)

**Notes:**
- Addresses are 64-bit NoC addresses (tile coordinate + offset)
- Transaction proceeds asynchronously to RISCV execution
- Multiple reads can be in-flight; `noc_async_read_barrier()` waits for all
- Maximum packet: 1 header + 256 data flits (16384 bytes)
- Alignment: 16-byte recommended for L1 targets
