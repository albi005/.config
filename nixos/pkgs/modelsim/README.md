# ModelSim - Intel FPGA Starter Edition (20.1.1.720)

Nix package for ModelSim ASE (Altera Starter Edition), an HDL simulator for Verilog and VHDL.

All ModelSim binaries are 32-bit (i386). The package uses `buildFHSEnv` with `multiArch` to provide a compatible runtime environment.

The installer is fetched directly from Intel's CDN — no manual download needed.

## Usage

### Run directly from GitHub

```sh
nix run github:albi005/.config#modelsim
```

This launches `vsim` (the GUI). To run a specific tool:

```sh
nix run github:albi005/.config#modelsim -- vcom -version
nix run github:albi005/.config#modelsim -- vlog -version
```

### Build locally

```sh
nix build github:albi005/.config#modelsim
./result/bin/vsim      # GUI
./result/bin/vcom      # VHDL compiler
./result/bin/vlog      # Verilog compiler
./result/bin/vlib      # library manager
```

### NixOS configuration

The package is included in the `netherite` host configuration. After `nixos-rebuild switch`, all ModelSim tools are available on `$PATH`.

## Included tools

The package exposes individual wrappers for all 45 ModelSim tools (`vsim`, `vcom`, `vlog`, `vlib`, `vsim`, `sccom`, etc.) in `$out/bin/`.
