# .config

## Clone
'''bash
git clone --recurse-submodules https://github.com/albi005/.config ~/.config

# if you forgot recurse-submodules above:
cd ~/.config && git submodule update --init --recursive

# init packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
:PackerSync

#


'''

## nvim cheat sheet

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
```

## tmux cheat sheet

```
C-b ?    help
C-b c    create window
C-b 1    select window 1
C-b w    window tree
C-b d    deattach
```
