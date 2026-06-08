# `noc_async_read` – NoC Asynchronous Read

**Category:** Data Movement (NoC)

**Syntax:** `noc_async_read(source_noc_addr, local_l1_addr, size)`

**Operation:** Initiate an asynchronous read from a remote NoC address into local L1 memory. Returns immediately; completion checked via `noc_async_read_barrier()`. Read requests always generate a response packet (unlike writes which can be posted). The NIU tracks outstanding transactions via hardware counters.

**x86 Equivalent:** No direct equivalent; similar to RDMA read

**Latency:** ~19 cycles (adjacent core) to ~200 cycles (cross-chip)

**Throughput:** Each NoC hop: one flit (512b) per cycle. Four independent NIU initiators available. Up to 15 outstanding transactions per transaction ID.

**Notes:**
- Addresses are 64-bit NoC addresses (tile coordinate + offset). This differs from Wormhole where addresses were 36-bit.
- Transaction proceeds asynchronously to RISCV execution
- Multiple reads can be in-flight; `noc_async_read_barrier()` waits for all
- Maximum packet: 1 header + 256 data flits (16384 bytes)
- Alignment: 16-byte recommended for L1 targets
- The underlying NIU hardware has a bug where `NOC_CMD_L1_ACC_AT_EN` cannot be safely used, but this is transparent to the firmware API user.

**Example:**
```cpp
// Declare L1 source and destination buffer addresses
uint32_t src_addr = src_buffer->address();  // remote NoC address
uint32_t dst_addr = l1_buffer->address();   // local L1 address
uint32_t size = 1024;

// Issue asynchronous read from remote NoC address into local L1
noc_async_read(src_addr, dst_addr, size);

// Wait for all outstanding reads to complete
noc_async_read_barrier();

// Data is now available at dst_addr in local L1
