# `dma_read` – TDMA Bulk Read

**Category:** Data Movement (TDMA-RISC)

**Syntax:** (configured via TDMA-RISC registers at `0xFFB1_1000-1FFF`)

**Operation:** Initiate a bulk DMA read from DRAM or remote L1 into local L1. Handled by the TDMA-RISC coprocessor, offloading the Baby RISC-V core.

**x86 Equivalent:** `memcpy` / DMA engine

**Notes:**
- Offloads data movement from the Baby RISC-V data-movement core
- Configured via MMIO registers; completion signaled via interrupt or polling
- Supports strided and rectangular data layouts
