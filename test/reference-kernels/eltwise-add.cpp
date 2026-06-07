// eltwise-add.cpp
// Reference: Elementwise addition compute kernel for Blackhole ttsim.
// Uses circular buffers and a compute kernel to add two vectors.
// Modern tt-metalium MeshDevice API.

#include <tt-metalium/host_api.hpp>
#include <tt-metalium/device.hpp>
#include <tt-metalium/distributed.hpp>
#include <tt-metalium/bfloat16.hpp>
#include <tt-metalium/tensor_accessor_args.hpp>
#include <cstdint>
#include <iostream>
#include <vector>

using namespace tt::tt_metal;

constexpr uint32_t NUM_TILES = 64;
constexpr uint32_t ELEMENTS_PER_TILE = tt::constants::TILE_WIDTH * tt::constants::TILE_HEIGHT;
constexpr uint32_t TILE_SIZE_BYTES = sizeof(bfloat16) * ELEMENTS_PER_TILE;

int main() {
    bool pass = true;
    try {
        constexpr int device_id = 0;
        std::shared_ptr<distributed::MeshDevice> mesh_device = distributed::MeshDevice::create_unit_mesh(device_id);
        distributed::MeshCommandQueue& cq = mesh_device->mesh_command_queue();

        uint32_t dram_buffer_size = TILE_SIZE_BYTES * NUM_TILES;

        distributed::DeviceLocalBufferConfig dram_config{
            .page_size = TILE_SIZE_BYTES,
            .buffer_type = BufferType::DRAM};
        distributed::ReplicatedBufferConfig rep_config{.size = dram_buffer_size};

        auto buffer_a = distributed::MeshBuffer::create(rep_config, dram_config, mesh_device.get());
        auto buffer_b = distributed::MeshBuffer::create(rep_config, dram_config, mesh_device.get());
        auto buffer_c = distributed::MeshBuffer::create(rep_config, dram_config, mesh_device.get());

        Program program = CreateProgram();
        distributed::MeshWorkload workload;
        auto device_range = distributed::MeshCoordinateRange(mesh_device->shape());
        constexpr tt::tt_metal::CoreCoord core = {0, 0};

        constexpr uint32_t tiles_per_cb = 2;
        tt::CBIndex src0_cb = tt::CBIndex::c_0;
        CreateCircularBuffer(program, core, CircularBufferConfig(
            tiles_per_cb * TILE_SIZE_BYTES,
            {{src0_cb, tt::DataFormat::Float16_b}})
            .set_page_size(src0_cb, TILE_SIZE_BYTES));
        tt::CBIndex src1_cb = tt::CBIndex::c_1;
        CreateCircularBuffer(program, core, CircularBufferConfig(
            tiles_per_cb * TILE_SIZE_BYTES,
            {{src1_cb, tt::DataFormat::Float16_b}})
            .set_page_size(src1_cb, TILE_SIZE_BYTES));
        tt::CBIndex dst_cb = tt::CBIndex::c_16;
        CreateCircularBuffer(program, core, CircularBufferConfig(
            tiles_per_cb * TILE_SIZE_BYTES,
            {{dst_cb, tt::DataFormat::Float16_b}})
            .set_page_size(dst_cb, TILE_SIZE_BYTES));

        std::vector<uint32_t> reader_compile_args;
        TensorAccessorArgs(*buffer_a).append_to(reader_compile_args);
        TensorAccessorArgs(*buffer_b).append_to(reader_compile_args);

        CreateKernel(program,
            "tt_metal/programming_examples/eltwise_binary/kernels/dataflow/read_tiles.cpp",
            core,
            DataMovementConfig{
                .processor = DataMovementProcessor::RISCV_0,
                .noc = NOC::RISCV_0_default,
                .compile_args = reader_compile_args});

        std::vector<uint32_t> writer_compile_args;
        TensorAccessorArgs(*buffer_c).append_to(writer_compile_args);

        CreateKernel(program,
            "tt_metal/programming_examples/eltwise_binary/kernels/dataflow/write_tile.cpp",
            core,
            DataMovementConfig{
                .processor = DataMovementProcessor::RISCV_1,
                .noc = NOC::RISCV_1_default,
                .compile_args = writer_compile_args});

        CreateKernel(program,
            "tt_metal/programming_examples/eltwise_binary/kernels/compute/tiles_add.cpp",
            core,
            ComputeConfig{.math_fidelity = MathFidelity::HiFi4});

        // Initialize A with sequential bfloat16 values, B with constant -1.0
        std::vector<bfloat16> a_data(ELEMENTS_PER_TILE * NUM_TILES);
        for (uint32_t i = 0; i < a_data.size(); i++) {
            a_data[i] = bfloat16(static_cast<float>(i % 4096));
        }
        constexpr float val_to_add = -1.0f;
        std::vector<bfloat16> b_data(ELEMENTS_PER_TILE * NUM_TILES, bfloat16(val_to_add));

        distributed::EnqueueWriteMeshBuffer(cq, buffer_a, a_data, false);
        distributed::EnqueueWriteMeshBuffer(cq, buffer_b, b_data, false);

        SetRuntimeArgs(program, 0, core, {(uint32_t)buffer_a->address(), (uint32_t)buffer_b->address(), NUM_TILES});
        SetRuntimeArgs(program, 1, core, {(uint32_t)buffer_c->address(), NUM_TILES});
        SetRuntimeArgs(program, 2, core, {NUM_TILES});

        workload.add_program(device_range, std::move(program));
        distributed::EnqueueMeshWorkload(cq, workload, false);
        distributed::Finish(cq);

        std::vector<bfloat16> result_vec;
        distributed::EnqueueReadMeshBuffer(cq, result_vec, buffer_c, true);

        constexpr float eps = 5.0f;
        for (uint32_t i = 0; i < result_vec.size(); i++) {
            float expected = static_cast<float>(a_data[i]) + val_to_add;
            float actual = static_cast<float>(result_vec[i]);
            if (std::abs(expected - actual) > eps) {
                std::cerr << "FAIL: mismatch at index " << i
                          << ": expected " << expected
                          << ", got " << actual << std::endl;
                pass = false;
                break;
            }
        }

        pass &= mesh_device->close();
    } catch (const std::exception& e) {
        std::cerr << "FAIL: " << e.what() << std::endl;
        return 1;
    }

    if (pass) {
        std::cout << "PASS" << std::endl;
        return 0;
    } else {
        std::cerr << "FAIL" << std::endl;
        return 1;
    }
}
