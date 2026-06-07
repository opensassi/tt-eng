# `noc_semaphore_wait` – NoC Semaphore Wait

**Category:** Synchronization

**Syntax:** `noc_semaphore_wait(local_l1_addr, threshold)`

**Operation:** Spin-wait until a semaphore value in local L1 reaches or exceeds the specified threshold.

**x86 Equivalent:** `pause` + spin loop / `futex`

**Latency:** Dependent on producer timing

**Notes:**
- Spin-wait; consumes CPU cycles
- Typically paired with `noc_semaphore_inc` on a remote core
- Used for barrier synchronization and producer-consumer handshakes
