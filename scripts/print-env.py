#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3

import os

env_vars = os.environ.items()
env_vars = sorted(env_vars)

for pair in env_vars:
    key = pair[0]
    value = pair[1]
    if value.startswith("/"):
        value = value.replace(':', '\n\033[31m: \033[0m')
    print(f"\033[32m{key} \033[0m{value}", end=None)

