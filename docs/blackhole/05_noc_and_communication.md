# NoC and Communication

## Overview

Blackhole has two independent Networks-on-Chip (NoC0 and NoC1) connecting all tiles in a 2D torus topology. Each operates at 1.35 GHz with 512-bit flit width.

## NoC Characteristics

| Property | NoC0 | NoC1 |
|----------|:---:|:---:|
| Routing | X-first (dimension order) | Y-first (dimension order) |
| Flit width | 512 bits (64 bytes) | 512 bits (64 bytes) |
| Clock | 1.35 GHz | 1.35 GHz |
| Max data flits/packet | 256 (16,384 bytes payload) | 256 |
| Addressing | 64-bit | 64-bit |
| Virtual channels | 16 (4 bits: 1 dateline + 2 class + 1 buddy) | 16 |

## NoC Transaction Types

| Type | Description | Max payload |
|------|-------------|:---:|
| Read | Contiguous span from receiver's address space, delivered back to initiator | 16,384 bytes |
| Write (posted) | Data from initiator to receiver, no acknowledgement | 16,384 bytes |
| Write (non-posted) | Data from initiator to receiver, with acknowledgement | 16,384 bytes |
| Broadcast write | Write to a rectangle of Tensix tiles | 16,384 bytes |
| Atomic | Read-modify-write on 128-bit aligned L1 address | 32-bit result |

## Performance

| Hop type | Throughput (per NoC) | Latency |
|----------|:---:|:---:|
| NIU → local router | 512 bits/cycle | ~5 cycles |
| Router → neighbor router | 512 bits/cycle/axis | 9 cycles |
| Router → local NIU | 512 bits/cycle | ~5 cycles |

**Effective bandwidth** depends on header-to-data ratio. Minimum: 4 bytes in 1 header flit (inefficient). Maximum: 16,384 bytes in 1 header + 256 data flits.

## NoC Primitives (as seen by Baby RISC-V)

| Primitive | Description | Function |
|-----------|-------------|----------|
| `noc_async_read` | Read from remote address → local L1 | `noc_async_read(addr, local_addr, size)` |
| `noc_async_write` | Write local L1 → remote address | `noc_async_write(local_addr, addr, size)` |
| `noc_async_write_multicast` | Write to rectangle of tiles | `noc_async_write_multicast(...)` |
| `noc_async_read_barrier` | Block until all reads complete | `noc_async_read_barrier()` |
| `noc_async_write_barrier` | Block until all writes complete | `noc_async_write_barrier()` |
| `noc_semaphore_inc` | Atomic increment at remote address | `noc_semaphore_inc(addr, delta)` |
| `noc_semaphore_wait` | Wait until local semaphore ≥ threshold | `noc_semaphore_wait(addr, val)` |
| `noc_async_atomic` | General atomic operation | `noc_async_atomic(addr, ...)` |

## Circular Buffers (CBs)

- **Purpose**: Primary inter-kernel communication within a Tensix core
- **Max per core**: 32 CBs (indices c0–c31)
- **Backed by**: L1 SRAM
- **Configuration**: Size per CB, page size, data format
- **Producer-consumer**: Reader kernel fills, compute kernel consumes, writer kernel drains
- **Global CBs**: Can be shared across cores (cross-core communication via NoC)

**Key CB operations** (Baby RISC-V API):

| Operation | Description |
|-----------|-------------|
| `cb_wait_front(cb, n)` | Wait until n tiles available in CB |
| `cb_pop_front(cb, n)` | Remove n tiles from front |
| `cb_reserve_back(cb, n)` | Reserve space for n tiles at back |
| `cb_push_back(cb, n)` | Commit n tiles at back |

## Ordering

NoC transactions are weakly ordered by default. Stronger ordering is available via:
- `NOC_CMD_VC_STATIC` — enforce ordering through static VC assignment
- `NOC_CMD_VC_LINKED` — link multiple request packets in same transaction
- Barriers (`noc_async_read_barrier`, `noc_async_write_barrier`)

## Latency Estimates

| Transfer path | Latency (cycles) |
|--------------|:---:|
| L1 load (L0 hit) | 2 |
| L1 load (L0 miss, no conflict) | ≥8 |
| NoC: core to adjacent core | ~19 (5 + 9 + 5) |
| NoC: core to DRAM | ~25-40 (depends on distance) |
| NoC: cross-chip (worst-case) | ~100-200 (many hops) |
| DRAM random access | ~300-400 |
| PCIe (host to device) | ~1-2 µs |

## Deadlock Freedom

Hardware ensures deadlock freedom for most common transaction patterns. Software is responsible when using:
- `NOC_CMD_VC_LINKED` (multi-packet transactions)
- Broadcast without path reservation (`NOC_CMD_PATH_RESERVE`)
- Arbitration priorities other than 0
