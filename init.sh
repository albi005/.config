#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash git gum neovim helix nixd nano
# https://nix.dev/tutorials/first-steps/reproducible-scripts

set -e # exit on error

export EDITOR=$(gum choose --header "EDITOR=" "hx" "nvim --clean" "nano")
export HOSTNAME=$(gum input --prompt "HOSTNAME=" --placeholder "nixos")

rm -fr ~/.config
git clone --recurse-submodules https://github.com/albi005/.config.git ~/.config

cd ~/.config/nixos
mkdir -p hosts/$HOSTNAME
cp /etc/nixos/hardware-configuration.nix hosts/$HOSTNAME
cp template.nix hosts/$HOSTNAME/configuration.nix
sed -i "s/HOSTNAME/$HOSTNAME/g" hosts/$HOSTNAME/configuration.nix

$EDITOR flake.nix hosts/$HOSTNAME/configuration.nix

git add .

sudo nixos-rebuild switch --flake ~/.config/nixos
