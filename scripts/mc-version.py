#!/usr/bin/env nix-shell
#! nix-shell -i python3 --pure
#! nix-shell -p pkgs.fd "(pkgs.python3.withPackages (python-pkgs: with python-pkgs; [ nbtlib tabulate ]))"

from dataclasses import dataclass
from tabulate import tabulate
from typing import Optional
import datetime
import nbtlib
import os
import subprocess
import json

@dataclass
class Level:
    seed: int = 0
    name: str = ""
    dirName: str = ""
    lastPlayed: datetime.datetime = datetime.datetime.fromtimestamp(0)
    versionId: Optional[int] = None
    versionName: Optional[str] = None
    path: str = ""

bad = []
def getTag(path: str) -> Optional[Level]:
    try:
        data: nbtlib.Compound = nbtlib.load(path)['Data']
    except:
        bad.append(path)
        return None

    version = data.get("Version")
    versionName = version["Name"] if version else None
    versionId = int(version["Id"]) if version else None
    dataVersion = data.get("DataVersion")
    assert versionId == dataVersion
    lastPlayed = datetime.datetime.fromtimestamp(data['LastPlayed'] / 1000) #.strftime("%Y-%m-%d %H:%M:%S")
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

    return Level(
        name = name,
        seed = int(seed),
        versionId = versionId,
        lastPlayed = lastPlayed,
        dirName = dirName,
        path = path,
        versionName = versionName
    )

os.chdir("/mnt/560AFE250AFE01B3/games/Minecraft")
fd_cmd = "fd --hidden --glob level.dat" # list path to every level.dat file

lines = subprocess.check_output(fd_cmd.split(" ")).decode("utf-8").split("\n")
assert lines[-1] == ""
lines = lines[:-1]

levels: list[Level] = []

# res = []
# lines = sorted(lines)
# for line in lines:
#     try:
#         src = nbtlib.load(line)["Data"].unpack(json=True)
#         dst = []
#         def check(s):
#             if not s in src:
#                 dst.append(s)
#             # dst.append(src.get(s))
#             # dst[s] = src.get(s)
#         check("Version")
#         check("LevelName")
#         check("DataVersion")
#         res.append(dst)
#     except:
#         bad.append(line)
# print(json.dumps(res, indent=True))
# exit()

for line in lines:
    if not line: continue
    level = getTag(line)
    if not level: continue
    levels.append(level)

levels.sort(key=lambda tag: [tag.lastPlayed])

print(tabulate(levels, headers='keys')) # type: ignore
for path in bad:
    print(path)

print()
print(f"Count: {len(levels)}")
print()

duplicates: dict[datetime.datetime, list[str]] = dict()
for level in levels:
    if level.lastPlayed not in duplicates:
        duplicates[level.lastPlayed] = list()
    duplicates[level.lastPlayed].append(level.path)
for item in duplicates.items():
    if len(item[1]) > 1:
        print(item)
print()

i = 0
ignored = []
for level in levels:
    seed = level.seed
    path = level.path
    lastPlayed = level.lastPlayed
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
pass
