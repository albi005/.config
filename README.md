# `/home/albi/.config`

## Install
1. [Install NixOS](https://nixos.org/download.html#download-nixos)
   - Use albi as username
   - Select *No desktop*
2. Log in as albi and run `sh <(curl -L alb1.hu/init)`

### Bootloader-specific settings
- BIOS instead of UEFI: 
```nix
# Use grub instead of systemd-boot:
# Disabling systemd-boot enables GRUB
boot.loader.systemd-boot.enable = false;
boot.loader.grub.useOSProber = true; # if dual booting
boot.loader.grub.device = "/dev/sda"; # if needed
```

- Garbage PC™ (Intel Atom Bay Trail Whatever): [Nix Wiki](https://nixos.wiki/wiki/Bootloader#Installing_x86_64_NixOS_on_IA-32_UEFI), [Arch Wiki](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface#UEFI_firmware_bitness)
```nix
boot.loader.efi.canTouchEfiVariables = false;
```

## Scripts
Some scripts you might find useful while working with Linux.
**If you have Nix** (`nix-shell`) installed,
all of them are **runnable using the below commands**,
[without having to install python](https://nix.dev/tutorials/first-steps/reproducible-scripts.html)
or any python packages.
The individual scripts contain more information on the specifications used and how they are implemented.

- **`./scripts/print-env.py`**
  - **Pretty-prints the current environment variables.** Sorts, colors and splits array variables onto new lines.
- **`./scripts/list-desktop-files.py`**
  - **Lists `.desktop` files.** These are used to populate app launchers and when opening URLs.
- **`./scripts/list-mimeapps-lists.py`**
  - **Lists `mimeapps.list` files.** These are used to set which `.desktop` file is used when opening a URL.
- **`./scripts/list-minecraft-saves.py`**
  - Lists Minecraft saves by searching for `level.dat` files. You will most likely have to update the code for your specific use case.
- **`./scripts/list-non-empty-dirs-from-env-var.py XDG_DATA_DIRS`**
  - Given the name of an environment variable (`XDG_DATA_DIRS` in the example), lists all non-empty directories referenced by it.
- **`./scripts/mkmedia.sh`**
  - Initializes a `/media` directory for *Linux ISOs*, using my preferred directory layout.


## Cheat sheets

### Alacritty

[Alacritty features](https://github.com/alacritty/alacritty/blob/master/docs/features.md)

```
ctrl+shift+space   vi mode
ctrl+shift+f       search forward
ctrl+shift+b       search backward
```

### nvim cheat sheet

```
d create dir
% create file
D delete file
 pv explorer
 pf search all
ctrl+p search git
 ps grep
 f format
 y ctrl+c
 n replace all ocurrences of current word
 x chmod x
 a harpoon add
ctrl+e harpoon toggle
ctrl+{htns} harpoon open
:sort
gx open url
gf open file
gv select last selection
```

- `K`: Displays **hover information** about the symbol under the cursor
- `gd`: Jumps to the **definition of** the **symbol** under the cursor
- `gD`: Jumps to the **declaration** of the symbol under the cursor
- `gi`: Lists all the **implementations** for the symbol under the cursor
- `go`: Jumps to the **definition of** the **type** of the symbol under the cursor
- `gr`: Lists all the **references** to the symbol under the cursor
- `gs`: Displays **signature** information about the symbol under the cursor
- `<F2>`: **Renames** all references to the symbol under the cursor
- `<F3>`: **Format** code in current buffer
- `<F4>`: Show **code actions**
- `gl`: Show diagnostics
- `[d`: previous diagnostic
- `]d`: next diagnostic

### tmux cheat sheet

```
C-b ?    help
C-b c    create window
C-b 1    select window 1
C-b w    window tree
C-b d    deattach
```

## Notes
- Before editing the `ags` config run `ags init` to set up JavaScript types

## Bookmarks

- https://github.com/hyprland-community/awesome-hyprland
