# `/home/albi/.config`

## Install
1. [Install NixOS](https://nixos.org/download.html#download-nixos)
   - Use `albi` as the username
   - Select *No desktop*
2. Log in as `albi` and run `sh <(curl -L alb1.hu/init)`

### Bootloader-specific settings

Some of the below options might be useful if you have an older setup.

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
Some [reproducible interpreted scripts](https://nix.dev/tutorials/first-steps/reproducible-scripts.html) you might find useful while working with Linux.
**If you have Nix installed** (you can run `nix-shell`), **all of them are runnable using the below commands**,
without having to explicitly install dependencies, like Python or Python packages.
The individual scripts contain more information on the specifications used and how they are implemented.

- `./scripts/print-env.py`
  - **Pretty-prints the current environment variables.** Sorts, colors and splits array variables onto new lines.
- `./scripts/list-desktop-files.py`
  - **Lists `.desktop` files.** These are used to populate app launchers and when opening URLs.
- `./scripts/list-mimeapps-lists.py`
  - **Lists `mimeapps.list` files.** These are used to set which `.desktop` file is used when opening a URL.
- `./scripts/list-minecraft-saves.py`
  - Lists Minecraft saves by searching for `level.dat` files. You will most likely have to update the code for your specific use case.
- `./scripts/list-non-empty-dirs-from-env-var.py XDG_DATA_DIRS`
  - Given the name of an environment variable (`XDG_DATA_DIRS` in the example), lists all non-empty directories referenced by it.
- `./scripts/mkmedia.sh`
  - Initializes a `/media` directory for *Linux ISOs*, using my preferred directory layout.


## Cheat sheets

```sh
# reboot into windows or another boot entry
sudo systemctl reboot --boot-loader-entry <Tab><Tab>

# remove previous NixOS generations and remove unused Nix derivations
sudo nix-collect-garbage -d

# remove unused Docker containers, networks, images, build cache
docker system prune -a
```

### Alacritty

[Alacritty features](https://github.com/alacritty/alacritty/blob/master/docs/features.md)

```
ctrl+shift+space   vi mode
ctrl+shift+f       search forward
ctrl+shift+b       search backward
```

### tmux cheat sheet

```
C-b ?    help
C-b c    create window
C-b 1    select window 1
C-b w    window tree
C-b d    deattach
```

### nvim cheat sheet

> [!NOTE]
> Some of these might not work with the current config. Use Helix (`hx`) instead, as it has better keybinds.

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

## Notes

- Before editing the `ags` config run `ags init` to set up JavaScript types
- Desktop layers:
  1. Linux (Kernel)
  2. systemd (Init System)
  3. Ly (Display Manager == Login Manger)
  4. uwsm (Session Manager)
  5. Hyprland (Wayland Compositor)

## Bookmarks

- https://github.com/hyprland-community/awesome-hyprland

## Deploy

Machines deploy themselves from GitHub via [`comin`](https://github.com/nlewo/comin) (pull-based GitOps). Dotfiles in `~/.config` stay a manual git checkout (`git pull`) so Hyprland, Helix, etc. hot-reload immediately.

### How it works

- **Merge to `main`**: `iron`, `slime`, `redstone`, and `netherite` poll `main` every 60s and `switch` automatically.
- **`water` (laptop)**: `comin` is enabled with automatic polling disabled (`poller.period = 0`) — run `gf` (`comin fetch`) whenever you want to update it.
- **Test on one host before merging**: push a `host/<hostname>` branch (e.g. `host/iron`). `comin` activates it with `test` (no boot entry); once the PR is merged and the branch deleted, the host returns to `main`.
- **Work sharing**: `netherite` and `water` pull custom derivations from `redstone` over Tailscale SSH and offload builds best-effort (`ssh-ng`), falling back locally after 5s when `redstone` is off. `iron` and `slime` do not share builders.

### Cheat sheet

```sh
# comin (aliases: gs = comin status, gf = comin fetch)
gs                               # check fetcher / builder / deployer state
gf                               # trigger a fetch & deploy now (required on water)
comin deployment list            # list recent deployments and boot entries
comin suspend && comin resume    # pause / resume automatic deploys
comin list --flake-url ./nixos   # list hosts defined in the flake

# interactive app / flake-input deploy from a desktop (redstone / netherite)
# picks flake input(s) with gum, updates flake.lock in a temp clone, opens a PR,
# pre-builds & copies the closure to iron before merging, merges, and runs `comin fetch`
deploy                           # interactive picker (or `deploy alb1` to skip picker)

# test a branch on a single host via comin
git push origin HEAD:host/iron
git push origin :host/iron       # return host to main

# local checkout (fail-safe / uncommitted local edits only; comin never touches ~/.config)
rb                               # sudo nixos-rebuild switch --flake ~/.config/nixos
nh os test ~/.config/nixos       # test local changes without touching boot entries
nh os switch ~/.config/nixos -H iron --target-host albi@iron --use-substitutes
update                           # nix flake update --flake ~/.config/nixos
```
