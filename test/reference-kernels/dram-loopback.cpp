// dram-loopback.cpp
// Reference: DRAM loopback copy kernel for Blackhole ttsim.
// Copy buffer A to buffer B, verify bit-exact match.
// Uses modern tt-metalium MeshDevice API.

#include <tt-metalium/host_api.hpp>
#include <tt-metalium/device.hpp>
#include <tt-metalium/distributed.hpp>
#include <tt-metalium/bfloat16.hpp>
#include <tt-metalium/tensor_accessor_args.hpp>
#include <cstdint>
#include <iostream>
#include <vector>

using namespace tt::tt_metal;

constexpr uint32_t NUM_TILES = 50;
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

        // L1 scratch buffer for the data movement kernel
        distributed::DeviceLocalBufferConfig l1_config{
            .page_size = TILE_SIZE_BYTES,
            .buffer_type = BufferType::L1};
        distributed::ReplicatedBufferConfig l1_rep_config{.size = TILE_SIZE_BYTES};
        auto l1_buffer = distributed::MeshBuffer::create(l1_rep_config, l1_config, mesh_device.get());

        Program program = CreateProgram();
        distributed::MeshWorkload workload;
        auto device_range = distributed::MeshCoordinateRange(mesh_device->shape());
        constexpr tt::tt_metal::CoreCoord core = {0, 0};

        std::vector<uint32_t> compile_time_args;
        TensorAccessorArgs(*buffer_a).append_to(compile_time_args);
        TensorAccessorArgs(*buffer_b).append_to(compile_time_args);

        KernelHandle copy_kernel_id = CreateKernel(
            program,
            "tt_metal/programming_examples/loopback/kernels/loopback_dram_copy.cpp",
            core,
            DataMovementConfig{
                .processor = DataMovementProcessor::RISCV_0,
                .noc = NOC::RISCV_0_default,
                .compile_args = compile_time_args});

        std::vector<bfloat16> input_vec(ELEMENTS_PER_TILE * NUM_TILES);
        for (uint32_t i = 0; i < input_vec.size(); i++) {
            input_vec[i] = bfloat16(static_cast<float>(i));
        }

        distributed::EnqueueWriteMeshBuffer(cq, buffer_a, input_vec, false);

        SetRuntimeArgs(program, copy_kernel_id, core, {
            (uint32_t)l1_buffer->address(),
            (uint32_t)buffer_a->address(),
            (uint32_t)buffer_b->address(),
            NUM_TILES});

        workload.add_program(device_range, std::move(program));
        distributed::EnqueueMeshWorkload(cq, workload, false);
        distributed::Finish(cq);

        std::vector<bfloat16> result_vec;
        distributed::EnqueueReadMeshBuffer(cq, result_vec, buffer_b, true);

        for (uint32_t i = 0; i < input_vec.size(); i++) {
            if (input_vec[i] != result_vec[i]) {
                std::cerr << "FAIL: mismatch at index " << i
                          << ": expected " << (float)input_vec[i]
                          << ", got " << (float)result_vec[i] << std::endl;
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
