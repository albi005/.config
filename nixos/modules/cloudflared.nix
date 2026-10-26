{ nixos-unstable, ... }:
{
  systemd.services.cloudflared = {
    description = "cloudflared";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      TimeoutStartSec = 0;
      Type = "notify";
      ExecStart = "${nixos-unstable.cloudflared}/bin/cloudflared --no-autoupdate tunnel run";
      Restart = "on-failure";
      RestartSec = "5s";
      EnvironmentFile = "/home/albi/secrets/cloudflared.env"; # put a `TUNNEL_TOKEN=eyJ...` into this
      User = "cloudflared";
      Group = "cloudflared";
    };
  };
  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };
}
