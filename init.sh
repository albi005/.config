#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash git
# https://nix.dev/tutorials/first-steps/reproducible-scripts

set -e # exit on error

read -p "Enter the new hostname: " HOSTNAME

rm -rf /tmp/.config
git clone --recurse-submodules https://github.com/albi005/.config.git /tmp/.config
cp -r /tmp/.config/* ~/.config

mkdir -p ~/.config/nixos/hosts/$HOSTNAME
cp -r /etc/nixos/* ~/.config/nixos/hosts/$HOSTNAME
sed -i 's/networking.hostName = "nixos"/networking.hostName = "'"$HOSTNAME"'"/g' ~/.config/nixos/hosts/$HOSTNAME/configuration.nix

sudo nixos-rebuild switch -I nixos-config=~/.config/nixos/hosts/$HOSTNAME/configuration.nix

git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
nvim --headless -c ":PackerSync" -c ":q"

gh auth login
