{
  pkgs,
  config,
  inputs,
  ...
}:
let
  t3code = inputs.nix-t3code.packages.${pkgs.stdenv.hostPlatform.system}.t3code;
in
{
  environment.systemPackages = [ t3code ];

  home-manager.users.albi.systemd.user.services.t3code = {
    Unit.Description = "T3 Code server";
    Service = {
      ExecStart = "${t3code}/bin/t3 --host t3-${config.networking.hostName}.alb1.hu --no-browser";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
