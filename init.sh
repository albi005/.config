#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash git neovim
# https://nix.dev/tutorials/first-steps/reproducible-scripts

set -e # exit on error

read -p "Enter the new hostname: " HOSTNAME

rm -fr ~/.config
git clone --recurse-submodules https://github.com/albi005/.config.git ~/.config

cd ~/.config/nixos
mkdir -p hosts/$HOSTNAME
cp /etc/nixos/hardware-configuration.nix hosts/$HOSTNAME
cp template.nix hosts/$HOSTNAME/configuration.nix
sed -i "s/HOSTNAME/$HOSTNAME/g" hosts/$HOSTNAME/configuration.nix
nvim --clean hosts/$HOSTNAME/configuration.nix

sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update
sudo nixos-rebuild switch -I nixos-config=$HOME/.config/nixos/hosts/$HOSTNAME/configuration.nix
