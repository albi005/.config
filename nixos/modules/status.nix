{
  config,
  lib,
  pkgs,
  ...
}:

let
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.flask
    ps.psutil
    ps.pystemd
    ps.gunicorn
  ]);

  src = pkgs.runCommand "status-api" { } ''
    mkdir -p $out
    cp ${./status.py} $out/status.py
  '';

  cfg = config.services.statusApi;
in
{
  options = {
    services.statusApi = {
      enable = lib.mkEnableOption "NixOS status API";
      host = lib.mkOption {
        type = lib.types.str;
        description = "Address on which the API will listen";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.status-api = {
      description = "NixOS status API";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pythonEnv}/bin/gunicorn status:app --bind ${cfg.host}:5550";
        WorkingDirectory = "${src}";
        User = "statusapi";
        Group = "statusapi";
      };
    };

    users = {
        users.statusapi = {
            group = "statusapi";
            isSystemUser = true;
        };
        groups.statusapi = {};
    };
  };
}
