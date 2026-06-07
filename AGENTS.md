# opencode Agent Instructions — @opensassi/opencode

This project uses the **@opensassi/opencode** skill pack.
All skills, scripts, and tooling are delivered via the npm package.

## Available Skills

| `skill` | Use case |
|---------|----------|
| `asm-optimizer` | SIMD/assembly optimization framework |
| `daily-evaluation` | Aggregate session evaluations into dashboards |
| `demo-video` | Produce narrated demo videos with multi-language subtitles |
| `git` | Rebase-based single-commit-per-session workflow |
| `issue` | GitHub issue management |
| `npm-optimizer` | Port an npm package to a C++ native addon |
| `opensassi` | Bootstrap a new project environment |
| `profiler` | Linux perf profiling + flamegraphs |
| `session-evaluation` | Generate structured session reports |
| `skill-manager` | Create/revise skills interactively |
| `system-design` | Interactive C++ spec authoring with diagrams |
| `system-design-review` | Seven-expert panel audit of technical specs |
| `todo` | Create issues + debugging skills from session context |

## Workflow

1. `skill opensassi` — Load the bootstrap skill. It exposes the full skills-index as a reference table.
2. Run `npx @opensassi/opencode <skill-name>` to load any sub-skill. The agent reads the output as the skill's full instructions.
3. Use the skill's commands. Scripts are run via `npx @opensassi/opencode run <path>` or `npx @opensassi/opencode run --skill <name> <path>`.

## Design Constraints

- No commits during development — all changes staged at finish-session time
- Single atomic commit per session
- Full test suite after every rebase
- Session evaluation is read-only (generate) / write-once (export)
- All skills, scripts, and AGENTS.md live in the npm package, not in the project

## Pipeline Guide: TT-Metalium Kernel Testing on ttsim

This project provides a staged pipeline for generating, compiling, running, and optimizing TT-Metalium kernels on the ttsim Blackhole simulator. All programs run on simulated hardware (no Tenstorrent silicon required).

### 1. Environment Setup

Every compiled kernel binary requires these environment variables and `mpirun`:

```bash
# Required env vars (stage scripts set these automatically)
export TT_METAL_HOME=<project>/external/tt-metal
export TT_METAL_RUNTIME_ROOT=$TT_METAL_HOME
export TT_METAL_SIMULATOR=<project>/external/ttsim/src/_out/release_bh/libttsim.so
export TT_METAL_SLOW_DISPATCH_MODE=1
export TT_METAL_DISABLE_SFPLOADMACRO=1
export LD_LIBRARY_PATH=\
  $TT_METAL_HOME/build/tt_metal:\
  $TT_METAL_HOME/build/tt_metal/third_party/umd/lib:\
  $TT_METAL_HOME/build/lib:\
  $TT_METAL_HOME/build/tt_stl:\
  /usr/lib/x86_64-linux-gnu/openmpi/lib

# All binaries must run via mpirun
mpirun --oversubscribe -np 1 ./kernel_binary
```

**Verification**: Run `bash scripts/env-check.sh` to check tool availability. The output goes to `results/env-check.json`.

### 2. The Stage Pipeline

The pipeline has 5 stages. Each stage is invoked through `run-stage.sh`:

```bash
bash src/stages/run-stage.sh <stage-id> [--iter N] [--variant L] [--task T]
```

| Stage | What it does | --task test | --task bench |
|-------|-------------|-------------|--------------|
| `stage0` | Environment bootstrap + sanity check | Toolchain + ttsim sanity compile | N/A |
| `stage1` | DRAM loopback copy kernel | Compile + run + verify B==A | N/A |
| `stage2` | Elementwise addition with CBs | Compile + run + verify C==A+B | perf + tt-npe profiling |
| `stage3` | Performance optimization | Same as stage2 test | Compare vs baseline |
| `stage4` | Automated iteration loop | Runs stages 1-3 in sequence | Archives experiments |

**Task modes:**
- `generate` — creates `src/generated/<stage>/` directory, signals agent to write kernel
- `test` — compiles kernel, runs full test suite, produces JSON artifacts
- `bench` — runs perf record + tt-npe profiling on a passing kernel

### 3. Writing a Kernel (Host Program)

TT-Metalium host programs use this pattern:

```cpp
#include <tt-metalium/host_api.hpp>
#include <tt-metalium/device.hpp>
#include <tt-metalium/distributed.hpp>
#include <tt-metalium/bfloat16.hpp>
#include <tt-metalium/tensor_accessor_args.hpp>
#include <cstdint>
#include <vector>

using namespace tt::tt_metal;

int main() {
    // 1. Create device (1x1 mesh)
    auto mesh = distributed::MeshDevice::create_unit_mesh(0);
    auto& cq = mesh->mesh_command_queue();

    // 2. Allocate DRAM and L1 buffers
    distributed::DeviceLocalBufferConfig dram_config{
        .page_size = 2048, .buffer_type = BufferType::DRAM};
    distributed::ReplicatedBufferConfig buf_config{.size = 2048 * 64};
    auto src = distributed::MeshBuffer::create(buf_config, dram_config, mesh.get());

    // 3. Create program and kernels
    Program prog = CreateProgram();
    distributed::MeshWorkload workload;
    auto kernel = CreateKernel(prog, "kernel_path.cpp",
        CoreCoord{0,0},
        DataMovementConfig{.processor = DataMovementProcessor::RISCV_0, .noc = NOC::RISCV_0_default});

    // 4. Write data, set runtime args, enqueue
    // Cast addresses to uint32_t (SetRuntimeArgs expects uint32_t)
    SetRuntimeArgs(prog, kernel, CoreCoord{0,0}, {(uint32_t)src->address(), 64});

    workload.add_program(MeshCoordinateRange(mesh->shape()), std::move(prog));
    distributed::EnqueueMeshWorkload(cq, workload, false);
    distributed::Finish(cq);

    // 5. Read back and verify (use bfloat16 epsilon of 5.0, not 1e-2)
    std::vector<bfloat16> result;
    distributed::EnqueueReadMeshBuffer(cq, result, dst_buffer, true);
    mesh->close();
}
```

**Key API differences from old tt-metal documentation:**
- **Includes**: use `#include <tt-metalium/host_api.hpp>` (not `"tt_metal/impl/device/device.hpp"`)
- **Device**: `MeshDevice::create_unit_mesh(0)` (not `CreateDevice(0)`)
- **Buffers**: `MeshBuffer::create(...)` (not `CreateBuffer(...)`)
- **Tensor accessors**: `TensorAccessorArgs(*mesh_buffer)` — the `*` dereferences MeshBuffer directly (not `->get_backing_buffer()`)
- **Address type**: `buffer->address()` returns `uint64_t` — cast to `(uint32_t)` for `SetRuntimeArgs`
- **Program execution**: `MeshWorkload` + `EnqueueMeshWorkload` + `Finish` pattern
- **Data movement**: `EnqueueWriteMeshBuffer` / `EnqueueReadMeshBuffer`
- **Verification epsilon**: use `5.0` not `1e-2` — bfloat16 has only 7 mantissa bits; at value 258, adjacent values are spaced by 2.0

### 4. Compiling and Running

Use the shared compile wrapper (encapsulates all include/link flags):

```bash
bash scripts/compile-kernel.sh kernel.cpp -o kernel_test

# Run with mpirun (always required)
TT_METAL_HOME=... TT_METAL_RUNTIME_ROOT=... TT_METAL_SIMULATOR=... \
TT_METAL_SLOW_DISPATCH_MODE=1 TT_METAL_DISABLE_SFPLOADMACRO=1 \
LD_LIBRARY_PATH=... \
mpirun --oversubscribe -np 1 ./kernel_test
```

The compile wrapper was built from flags extracted at `external/tt-metal/build/tt_metal/CMakeFiles/tt_metal.dir/flags.make`. If tt-metal is updated, regenerate paths from that file.

### 5. Mock Agent Testing (No LLM Required)

Test the pipeline end-to-end using reference kernels:

```bash
# Stage 1: copy reference kernel to generated dir
bash scripts/mock-agent.sh stage1

# Compile + test (produces stage-result.json)
bash src/stages/run-stage.sh stage1 --iter 1 --task test

# Read the result
cat results/stage1/stage-result.json | jq '.status'

# Stage 2: elementwise addition
bash scripts/mock-agent.sh stage2
bash src/stages/run-stage.sh stage2 --iter 1 --task test

# Benchmark the passing kernel
bash src/stages/run-stage.sh stage2 --iter 1 --task bench

# Compare two experiment results
python3 src/evaluation/compare.py results/stage2/benchmark results/stage2/benchmark
```

### 6. Correctness Feedback Loop

When a test fails, the agent follows this pattern:

1. **Compile error**: read `results/<stage>/test-suite/failed-tests/compile_error.json`
   - `diagnostics.compiler_output_first_lines` contains the first 20 lines of compiler stderr
   - This gives immediate feedback without parsing a large log file
2. **Runtime error**: read `results/<stage>/test-suite/failed-tests/<test_name>.json`
   - `diagnostics.exit_code`, `diagnostics.output_file` for the full log
3. **Fix the kernel** based on the error, then retry with the same `--task test` command
4. Repeat until status=pass

### 7. Performance Feedback Loop

After all tests pass:

1. Run benchmark: `run-stage.sh stage2 --task bench`
2. Results in `results/<stage>/benchmark/metrics.json`:
   - **Primary metrics** (from tt-npe): `noc_util_pct`, `dram_bw_util_pct`
   - **Supplementary** (from perf, diagnostic only): `cycles`, `instructions`, `ipc`
3. Generate a new kernel design based on the metrics
4. Run the correctness loop first (test), then re-benchmark
5. Compare: `python3 src/evaluation/compare.py <baseline-dir> <candidate-dir>`
6. Archive accepted improvements to `results/experiments/<NNN>-<label>/`

### 8. Common Errors and Resolutions

| Error | Cause | Fix |
|-------|-------|-----|
| "Root Directory is not set" | `TT_METAL_RUNTIME_ROOT` missing | Set to tt-metal source root |
| `No such file or directory` at `.ld` files | Firmware toolchain directories missing | `mkdir -p runtime/hw/toolchain/{wormhole,blackhole}` before building tt-metal |
| `MPI_Init_thread` failed | Direct execution without mpirun | Wrap in `mpirun --oversubscribe -np 1` |
| `undefined reference to ompi_mpi_*` | Missing MPI link flags | Add `-lmpi -lmpi_cxx` at end of link command |
| `fatal error: tt_metal/impl/device/device.hpp` | Wrong include path | Use `<tt-metalium/host_api.hpp>` with `-I$TT_METAL_HOME/tt_metal/api` |
| `bfloat16` has no member `to_float` | Wrong API method | Use `(float)variable` via `operator float()` |
| Narrowing conversion on `address()` | `DeviceAddr` is `uint64_t` | Cast to `(uint32_t)` for `SetRuntimeArgs` |
| Output mismatch at high values | bfloat16 mantissa precision (7 bits) | Use epsilon `5.0` not `1e-2` |
| `cannot find -lttsim_bh` | Library is named `libttsim.so` not `libttsim_bh.so` | Use `-lttsim` |
| Stack trace ends at `open output file` | CPM cache include paths missing | Add `.cpmcache/<pkg>/<hash>/include` dirs |
| Stage script not found `stageX-run.sh` | Script naming convention | Name file `<stage-id>-run.sh` (not `stageX-bootstrap.sh`) |

### 9. File Reference

| Resource | Path |
|----------|------|
| Stage entry point | `src/stages/run-stage.sh` |
| Compile wrapper (all include/link flags) | `scripts/compile-kernel.sh` |
| Environment verification | `scripts/env-check.sh` |
| Reference kernel source | `test/reference-kernels/dram-loopback.cpp` |
| Reference kernel source | `test/reference-kernels/eltwise-add.cpp` |
| Mock agent (CI testing no LLM) | `scripts/mock-agent.sh` |
| Reference kernel Makefile | `test/reference-kernels/Makefile` |
| Prompt templates | `prompts/stage1-copy-kernel.md` |
| | `prompts/stage2-eltwise-add.md` |
| | `prompts/stage3-optimize.md` |
| System context (TT-metal programming model) | `prompts/system-context.md` |
| Stage definitions + thresholds | `config/stages.json` |
| Chip config + env var definitions | `config/hardware.json` |
| tt-npe CSV parser | `src/evaluation/parse-tt-npe.py` |
| perf stat parser | `src/evaluation/parse-perf.py` |
| A/B experiment comparison | `src/evaluation/compare.py` |
| tt-metal source + build | `external/tt-metal/` |
| ttsim source + build | `external/ttsim/` |
| ISA documentation reference | `external/tt-isa-documentation/` |
| Stage results | `results/<stage>/stage-result.json` |
| Compile log | `results/<stage>/compile-log.txt` |
| Failed test details | `results/<stage>/test-suite/failed-tests/*.json` |
| Benchmark metrics | `results/<stage>/benchmark/metrics.json` |
| Experiment archive | `results/experiments/<NNN>-<label>/` |
| Technical specification | `technical-specification.md` |
