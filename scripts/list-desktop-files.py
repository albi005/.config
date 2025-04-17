#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3

# Lists all .desktop files that are reachable by xdg-mime and xdg-open

# Based on $(which xdg-mime) desktop_file_to_binary()
# and https://specifications.freedesktop.org/menu-spec/menu-spec-1.0.html ($XDG_DATA_DIRS/applications/)

import os
import glob

home = os.environ.get("HOME")
if not home: raise TypeError()

xdg_data_home = os.environ.get("XDG_DATA_HOME") or (home + "/.local/share")
xdg_data_dirs = os.environ.get("XDG_DATA_DIRS") or ("/usr/local/share:/usr/share")
xdg_data_dirs = [xdg_data_home] + xdg_data_dirs.split(":")

for dir in xdg_data_dirs:
    if not os.path.exists(dir):
        continue
    print(f"\033[32m{dir} \033[0m")
    for subdir in ["/applications/", "/applications/*/", "/applnk/", "/applnk/*/"]:
        query = dir + subdir + "*.desktop"
        files = glob.glob(query)
        if len(files) == 0:
            continue
        print(f"  \033[30m{subdir}\033[0m")
        for file in files: 
            basename = os.path.basename(file)
            filename = basename[:-8]
            print(f"    {filename}\033[30m.desktop\033[0m")
