# AGENTS.md — /home/albi/.config

## Repo overview

This is a **NixOS dotfiles repo** where `~/.config` itself is the git working tree.
It manages the full system configuration (`nixos/` flake), desktop environment configs,
and a collection of utility scripts.

## Git: whitelist .gitignore

The `.gitignore` blocks everything (`*`), then un-ignores specific directories.
To track a new directory, add a `!/dirname/**` line to `.gitignore`.
Generated/host-specific files must also be excluded there
(e.g. `hypr/host.conf`, `ags/types`, `.direnv`, `result`).

The default branch is `main`. Push auto-setup-remote is enabled.

## NixOS rebuild

```sh
sudo nixos-rebuild switch --flake /home/albi/.config/nixos
```

Bash alias: `rb` (rebuild with lockfile), `rbs` (rebuild without writing lockfile).

## Flake architecture

```
nixos/
  flake.nix        — 5 hosts: iron, netherite, redstone, slime, water + modelsim package
  template.nix     — new-host template (imports base.nix + desktop.nix + hardware-config)
  hosts/<name>/    — host-specific configuration.nix
  modules/         — shared NixOS modules (base, desktop, dev, media, …)
  pkgs/            — custom Nix packages
```

`home-manager` config is embedded in `nixos/modules/base.nix` under `home-manager.users.albi`.
Bash aliases, yazi config, tmux, and dotfile templates all live there.

## State versions — DO NOT CHANGE

- `home.stateVersion = "23.05"` in `nixos/modules/base.nix` (line ~327)
- `system.stateVersion = "23.05"` in `nixos/modules/base.nix` (line ~390)

## Nix tooling

- **Formatter**: `nixfmt` (official Nix formatter)
- **LSPs**: `nil` (refactorings), `nixd` (completion, package/option docs with versions)
- **Channel**: primary channel is `nixos-2511`; individual packages can be pulled from `nixos-unstable`
- **Editor config**: `nixos/.editorconfig` — 2-space indent for `.nix` files

## Desktop environment

- **WM**: Hyprland (`hypr/hyprland.conf`)
- **Shell**: **Quickshell 0.2.1** (`quickshell/`) — the active shell/bar. Has its own `quickshell/AGENTS.md` with reference links.
- **AGS** (`ags/`) is the **legacy** AGS v1 config, preserved for reference only. Edit `quickshell/`, not `ags/`.
- **Hyprland host config**: `hypr/host.conf` is **Nix-generated** and gitignored. Do not edit it directly; it is sourced from `hyprland.conf` on the last line.

## Scripts

Scripts in `scripts/` are **reproducible** via Nix: `scripts/shell.nix` provides Python dependencies.
They can be run with `nix-shell scripts/shell.nix --run 'python3 scripts/<name>.py'`
or by entering the directory (direnv auto-loads via `.envrc` with `use nix`).

## Bootstrapping a fresh machine

`init.sh` (fetched via `curl`, see README.md) clones this repo, copies hardware config,
creates a new host from `template.nix`, then runs `nixos-rebuild switch --flake`.

## opencode

OpenCode plugin v1.14.19 is configured in `opencode/package.json`.
