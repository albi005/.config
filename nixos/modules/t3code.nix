{
  pkgs,
  config,
  inputs,
  ...
}:
let
  t3code = inputs.nix-t3code.packages.${pkgs.stdenv.hostPlatform.system}.t3code-nightly;
in
{
  environment.systemPackages = [ t3code ];

  services.tailscale.extraSetFlags = [ "--operator=albi" ];

  systemd.services.t3code = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "tailscaled.service"
      "tailscaled-set.service"
    ];
    after = [
      "tailscaled.service"
      "tailscaled-set.service"
    ];
    path = [ config.services.tailscale.package ];
    environment = {
      HOME = "/home/albi";
    };
    serviceConfig = {
      User = "albi";
      Group = "users";
      WorkingDirectory = "/home/albi";
      ExecStart = "${t3code}/bin/t3 serve --tailscale-serve --tailscale-serve-port 3773";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
