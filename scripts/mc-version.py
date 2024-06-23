#!/usr/bin/env nix-shell
#! nix-shell -i python3 --pure
#! nix-shell -p pkgs.fd "(pkgs.python3.withPackages (python-pkgs: with python-pkgs; [ nbtlib tabulate ]))"

import os
import subprocess
import nbtlib
import datetime
from tabulate import tabulate

bad = []
def getTag(path: str):
    try:
        data: nbtlib.Compound = nbtlib.load(path)['Data']
    except:
        bad.append(path)
        return []

    if data.get('Version'):
        version = data['Version']['Name']
    else:
        version = ''
    lastPlayed = datetime.datetime.fromtimestamp(data['LastPlayed'] / 1000).strftime("%Y-%m-%d %H:%M:%S")
    name = data['LevelName']
    if path == "level.dat":
        path = "./level.dat"
    assert path.endswith("/level.dat")
    path = path[:-10]
    dirName = path.split('/')[-1]
    seed: nbtlib.Long
    if data.get('WorldGenSettings'):
        seed = data['WorldGenSettings']["seed"]
    else:
        seed = data['RandomSeed']

    return [name, int(seed), version, lastPlayed, dirName, path]

# Run fd -H --exclude 'level.dat_old' --exclude 'level.dat_mcr' level.dat

lines = subprocess.check_output(["fd", "-H", "--exclude", "level.dat_old", "--exclude", "level.dat_mcr", "level.dat"]).decode("utf-8").split("\n")
tags = []
for line in lines:
    if not line: continue
    tag = getTag(line)
    if not tag: continue
    tags.append(tag)

tags.sort(key=lambda tag: [tag[1], tag[3]])

print(tabulate(tags, ["Name", "Seed", "Version", "Last Played", "Dir", "Path"]))
for path in bad:
    print(path)

print()
print(f"Count: {len(tags)}")
print()

duplicates: dict[str, list[str]] = dict()
for tag in tags:
    path = tag[5]
    lastPlayed = tag[3]
    if lastPlayed not in duplicates:
        duplicates[lastPlayed] = list()
    duplicates[lastPlayed].append(path)
for item in duplicates.items():
    if len(item[1]) > 1:
        print(item)
print()

i = 0
ignored = []
for tag in tags:
    seed = tag[1]
    path = tag[5]
    lastPlayed = tag[3]
    if seed == 2996658:
        if "Hmm" in path or "Copy" in path or "Jurassic" in path:
            ignored.append(path)
            continue
        #print(f"rsync -r --progress '{path}' ~/.local/share/PrismLauncher/instances/uwu/.minecraft/saves/{i:02d}")
        #print(f"restic backup --time '{lastPlayed}' '{path}' --tag vkt")
        #print(f"rsync -r --progress '{path}' ~/.local/share/PrismLauncher/instances/uwu/.minecraft/saves/{i:02d}")
        print(f"(cd '{path}' && restic backup --time '{lastPlayed}' --tag vkt --group-by tags --exclude .git .)")
        i += 1

print()
for i in ignored:
    print(i)
