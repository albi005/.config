# ModelSim - Intel FPGA Starter Edition (20.1.1.720)

HDL simulator for Verilog and VHDL, packaged with Nix.

## Running

1. [Install Nix](https://nixos.org/download/)
2. Run:
   ```sh
   nix run "github:albi005/.config?dir=nixos#modelsim"
   ```

This opens the `vsim` GUI. The installer (~1.4 GB) is downloaded automatically from Intel's CDN on first run.

To run a specific tool instead:

```sh
nix run "github:albi005/.config?dir=nixos#modelsim" -- vcom -version   # VHDL compiler
nix run "github:albi005/.config?dir=nixos#modelsim" -- vlog -version   # Verilog compiler
nix run "github:albi005/.config?dir=nixos#modelsim" -- vlib --help     # library manager
```

## Adding to a NixOS flake

In `flake.nix`, add the input:

```nix
inputs.modelsim.url = "github:albi005/.config?dir=nixos";
```

Then in your NixOS module, add the package to your user or system packages:

```nix
{ inputs, pkgs, ... }:
{
  users.users.yourname.packages = [
    inputs.modelsim.packages.${pkgs.stdenv.hostPlatform.system}.modelsim
  ];
}
```
