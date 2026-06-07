# External Dependencies

This directory contains cloned repositories of external projects needed by the TT-Metalium LLM Agent Validation Pipeline.

## ttsim

- **Repo**: https://github.com/tenstorrent/ttsim
- **Purpose**: Full-system simulator of Tenstorrent hardware
- **Target chip**: Blackhole (`libttsim_bh.so`)
- **Clone**: `git clone --depth 1 https://github.com/tenstorrent/ttsim.git external/ttsim`
- **Build**: `cd external/ttsim && ./make.py :build`

## tt-metal

- **Repo**: https://github.com/tenstorrent/tt-metal
- **Purpose**: TT-Metalium low-level programming API
- **Clone**: `git clone --depth 1 https://github.com/tenstorrent/tt-metal.git external/tt-metal`
- **Build**: `cd external/tt-metal && mkdir build && cd build && cmake .. && make -j$(nproc)`

## Environment Variables

After building, set these before running stages:

```bash
export TT_METAL_HOME=/path/to/external/tt-metal
export TT_METAL_SIMULATOR=/path/to/external/ttsim/src/_out/release_bh/libttsim.so
export TT_METAL_SLOW_DISPATCH_MODE=1
export TT_METAL_DISABLE_SFPLOADMACRO=1
```

## SOC Descriptor

Copy the SOC descriptor alongside the simulator binary:

```bash
cp $TT_METAL_HOME/tt_metal/soc_descriptors/blackhole_140_arch.yaml \\
  $(dirname $TT_METAL_SIMULATOR)/soc_descriptor.yaml
```
