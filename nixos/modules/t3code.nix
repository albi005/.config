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

  systemd.services.t3code = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    environment = {
      HOME = "/home/albi";
    };
    serviceConfig = {
      User = "albi";
      Group = "users";
      WorkingDirectory = "/home/albi";
      ExecStart = "${t3code}/bin/t3 --host t3-${config.networking.hostName}.alb1.hu --no-browser";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
