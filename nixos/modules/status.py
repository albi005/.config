#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.flask python3Packages.pystemd

from flask import Flask
from pystemd.systemd1 import Unit

app = Flask(__name__)

@app.route('/')
def get_nixos_rebuild_status():
    try:
        unit = Unit(b'nixos-upgrade.service')
        unit.load()
        return {
            'exitCode': unit.Service.ExecMainStatus,
            'exitTime': unit.Service.ExecMainExitTimestamp
        }
    except Exception as e:
        return {'error': str(e)}, 500

#app.run(host='0.0.0.0', port=5000)
