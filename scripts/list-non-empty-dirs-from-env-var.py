#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3

import os
import sys

KEY = sys.argv[1]
xdg_data_dirs = os.environ.get(KEY)
if not isinstance(xdg_data_dirs, str): raise TypeError(f"{KEY} is not a string")

xdg_data_dirs = xdg_data_dirs.split(':')

for path in xdg_data_dirs:
    try:
        ls = os.listdir(path)
        if len(ls) > 0:
            print(path)
    except: pass
