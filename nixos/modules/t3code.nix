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
      "network-online.target"
      "tailscaled.service"
      "tailscaled-set.service"
    ];
    after = [
      "network-online.target"
      "tailscaled.service"
      "tailscaled-set.service"
    ];
    path = [ config.services.tailscale.package ];
    preStart = ''
      for ((i = 0; i < 60; i++)); do
        if tailscale status --peers=false >/dev/null 2>&1 && tailscale serve status >/dev/null 2>&1; then
          exit 0
        fi
        sleep 1
      done
    '';
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
