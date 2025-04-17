#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3

# Lists all mimeapps.list files that are checked by xdg-mime and xdg-open
# Paths that exist are written to stdout, while those that don't are written to stderr
# nvim $(python3 ~/.config/scripts/list-mimeapps-lists.py)

# Based on $(which xdg-mime) defapp_generic()
# https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-latest.html
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-0.6.html

import os
import sys

home = os.environ.get("HOME")
if not home: raise TypeError()

xdg_config_home = os.environ.get("XDG_CONFIG_HOME") or (home + "/.config")
xdg_config_dirs = os.environ.get("XDG_CONFIG_DIRS") or ("/usr/local/share:/usr/share")
xdg_config_dirs = [xdg_config_home] + xdg_config_dirs.split(":")

xdg_data_home = os.environ.get("XDG_DATA_HOME") or (home + "/.local/share")
xdg_data_dirs = os.environ.get("XDG_DATA_DIRS") or ("/usr/local/share:/usr/share")
xdg_data_dirs = [xdg_data_home] + xdg_data_dirs.split(":")

desktops = os.environ.get("XDG_CURRENT_DESKTOP")
if not desktops:
    print("$XDG_CURRENT_DESKTOP not set, ignoring desktop specific files")
desktops = desktops.lower().split(":") if desktops else []

def check_file(path):
    exists = os.path.isfile(path)
    if exists:
        print(path)
    else:
        print(f"\033[30m{path}\033[0m", file=sys.stderr)

def check_mimeapps_list(dir):
    for desktop in desktops + [""]:
        prefix = f"{desktop}-" if desktop else ""
        mimeapps_list = f"{dir}/{prefix}mimeapps.list"
        check_file(mimeapps_list)

for dir in xdg_config_dirs:
    check_mimeapps_list(dir)
for dir in xdg_data_dirs:
    check_mimeapps_list(dir + "/applications")

xdg_menu_prefixes = os.environ.get("XDG_MENU_PREFIX")
xdg_menu_prefixes = xdg_menu_prefixes.split(":") if xdg_menu_prefixes else []
for x in xdg_data_dirs:
    for prefix in xdg_menu_prefixes + [""]:
        check_file(f"{x}/applications/{prefix}defaults.list")
        check_file(f"{x}/applications/{prefix}mimeinfo.cache")
