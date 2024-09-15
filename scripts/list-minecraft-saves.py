#!/usr/bin/env nix-shell
#! nix-shell --pure -p pkgs.fd "(pkgs.python3.withPackages (python-pkgs: with python-pkgs; [ nbtlib tabulate ]))" -i python3 

from dataclasses import dataclass
from tabulate import tabulate
from typing import Iterable, Optional
import datetime
import nbtlib
import os
import subprocess

# https://minecraft.wiki/w/Level.dat

def partition(f, iterable):
    trues = []; falses = []
    for x in iterable:
        if f(x): trues.append(x)
        else: falses.append(x)
    return trues, falses

@dataclass
class Level:
    name: str = ""
    dirName: str = ""
    path: str = ""
    seed: int = 0
    lastPlayed: datetime.datetime = datetime.datetime.fromtimestamp(0)
    versionName: Optional[str] = None
    containerDir: str = ""
    versionId: Optional[int] = None

os.chdir("/mnt/560AFE250AFE01B3/games/Minecraft/")
lines = subprocess.run("fd --hidden --absolute-path --glob level.dat", shell=True, text=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.strip().split("\n")

levels: Iterable[Level] = []
unparseablePaths = []

for path in lines:
    try:
        nbt: nbtlib.Compound = nbtlib.load(path)['Data']
    except:
        unparseablePaths.append(path)
        continue

    version = nbt.get("Version")
    versionName = version["Name"] if version else None
    versionId = int(version["Id"]) if version else None
    assert versionId == nbt.get("DataVersion")

    assert path.endswith("/level.dat")
    path = path[:-10]

    levels.append(Level(
        name = nbt['LevelName'],
        seed = int(nbt['WorldGenSettings']["seed"] if nbt.get('WorldGenSettings') else nbt['RandomSeed']),
        versionName = versionName,
        versionId = versionId,
        lastPlayed = datetime.datetime.fromtimestamp(nbt['LastPlayed'] / 1000),#.strftime("%Y-%m-%d %H:%M:%S")
        dirName = path.split('/')[-1],
        path = "rm -r '" + path + "'",
        containerDir = path[:path.rfind('/')]
    ))
levels.sort(key=lambda tag: [tag.dirName])
print(tabulate(levels, headers='keys')) # type: ignore
print(f"\n# Level count: {len(levels)}")

print("\n# Unparseable")
for path in unparseablePaths:
    print(path)

print("\n# Duplicates")
duplicates: dict[datetime.datetime, list[str]] = dict()
for level in levels:
    if level.lastPlayed not in duplicates:
        duplicates[level.lastPlayed] = []
    duplicates[level.lastPlayed].append(level.path)
for item in duplicates.items():
    if len(item[1]) > 1: print(item)

levels = filter(lambda level: level.seed == 2996658, levels)

print("\n# Ignored")
blacklist = ["Hmm", "Copy", "Jurassic"]
def shouldKeep(level):
    if any(True for ignoredWord in blacklist if ignoredWord in level.path):
        print(level)
        return False
    return True
levels = list(filter(shouldKeep, levels))

print("\n# Result")
for (i, level) in enumerate(levels):
    #print(f"rsync -r --progress '{path}' ~/.local/share/PrismLauncher/instances/uwu/.minecraft/saves/{i:02d}")
    #print(f"restic backup --time '{lastPlayed}' '{path}' --tag vkt")
    #print(f"rsync -r --progress '{path}' ~/.local/share/PrismLauncher/instances/uwu/.minecraft/saves/{i:02d}")
    print(f"(cd '{level.path}' && restic backup --time '{level.lastPlayed}' --tag vkt --group-by tags --exclude .git .)")
for (i, level) in enumerate(levels):
    print(f"restic backup --time '{level.lastPlayed}' --tag vkt --group-by tags --exclude .git '{level.path}'")

pass
