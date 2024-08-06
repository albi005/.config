#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.flask python3Packages.pystemd

from flask import Flask
from pystemd.systemd1 import Unit, Manager

app = Flask(__name__)

def addUnit(res: dict, name):
    unit = Unit(str.encode(f"{name}.service"))
    unit.load()
    res[name] = {
        'exitCode': unit.Service.ExecMainStatus,
        'exitTime': unit.Service.ExecMainExitTimestamp
    }

@app.route('/')
def get_nixos_rebuild_status():
    try:
        res = {}
        addUnit(res, "nixos-upgrade")
        addUnit(res, "restic-backups-TODO")
        return res
    except Exception as e:
        return {'error': str(e)}, 500

#app.run(host='0.0.0.0', port=5000)

manager = Manager()
manager.load()
manager = manager.Manager
units = manager.ListUnitsByNames([str.encode("restic")])
print()
