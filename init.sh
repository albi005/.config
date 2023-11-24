#!/bin/bash

read -p "Enter the new hostname: " NEW_HOSTNAME

git clone --recurse-submodules https://github.com/albi005/.config.git /tmp/mytempconfig

cp -r /tmp/mytempconfig ~/.config

mkdir -p ~/.config/nixos/hosts/$NEW_HOSTNAME

cp -r /etc/nixos/* ~/.config/nixos/hosts/$NEW_HOSTNAME

# Update hostName
sed -i 's/networking.hostName = "nixos"/networking.hostName = "'"$NEW_HOSTNAME"'"/g' ~/.config/nixos/hosts/$NEW_HOSTNAME/configuration.nix

sudo nixos-rebuild switch -I nixos-config=~/.config/nixos/hosts/$NEW_HOSTNAME/configuration.nix

# Clone packer.nvim
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Run :PackerSync
nvim --headless -c ":PackerSync" -c ":q"

gh auth login
