# ~/.config

## Install
1. [Install NixOS](https://nixos.org/download.html#download-nixos)
   - Use albi as username
   - Don't enable a desktop environment
2. Log in as albi and run `sh <(curl -L http://alb1.hu/init)`

### Bootloader edge cases
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
boot.loader.efi.canTouchEfiVariables = true;
```

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

n	gd				definition
n	K				hover
n	<leader>vws		workspace_symbol
n	<leader>vd		open_float
n	[d				goto_next
n	]d				goto_prev
n	<leader>vca		code_action
n	<leader>vrr		references
n	<leader>vrn		rename
i	<C-h>			signature_help
```

### tmux cheat sheet

```
C-b ?    help
C-b c    create window
C-b 1    select window 1
C-b w    window tree
C-b d    deattach
```

## Bookmarks

- https://github.com/hyprland-community/awesome-hyprland
