{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
        ../../pkgs/qbittorrent.nix
    ];

    networking.hostName = "netherite";

    users.users.albi.packages = with pkgs; [
        jetbrains.clion
        jetbrains.idea-ultimate
        jetbrains.rider
        prismlauncher
    ];

    environment.systemPackages = with pkgs; [
        vlc
    ];

    virtualisation.docker.enable = true;

    users.groups.media.gid = 1337;

    services = {
        jellyfin.enable = true;
        jellyfin.group = "media";

        jellyseerr.enable = true;

        sonarr.enable = true;
        sonarr.group = "media";

        radarr.enable = true;
        radarr.group = "media";

        prowlarr.enable = true;

        qbittorrent.enable = true;
        qbittorrent.group = "media";
        qbittorrent.port = 9797;

        nginx = {
            enable = true;
            virtualHosts =
            let
                tailscaleToLocalhost = port: {
                    locations."/".proxyPass = "http://localhost:${builtins.toString port}";
                    locations."/".proxyWebsockets = true;
                    listen = [ {
                        addr = "100.69.0.1";
                        port = 80;
                        ssl = false;
                    } ];
                };
            in {
                "jellyfin.alb1.hu" = tailscaleToLocalhost 8096;
                "jellyseer.alb1.hu" = tailscaleToLocalhost 5055;
                "sonarr.alb1.hu" = tailscaleToLocalhost 8989;
                "radarr.alb1.hu" = tailscaleToLocalhost 7878;
                "prowlarr.alb1.hu" = tailscaleToLocalhost 9696;
                "torrent.alb1.hu" = tailscaleToLocalhost 9797;
                "turtle.alb1.hu" = {
                    root = "/var/lib/turtle";
                    listen = [{ addr = "127.0.0.1"; port = 80; ssl = false; }];
                    extraConfig = ''
                        autoindex on;
                        default_type text/plain;
                        index install.lua;
                    '';
                };
            };
        };
    };

    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            flaresolverr = {
                image = "ghcr.io/flaresolverr/flaresolverr:latest";
                ports = [ "127.0.0.1:8191:8191" ];
            };
        };
    };

    systemd.services.cloudflared = {
        description = "cloudflared";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            TimeoutStartSec = 0;
            Type = "notify";
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel run --token $CLOUDFLARED_TOKEN";
            Restart = "on-failure";
            RestartSec = "5s";
            EnvironmentFile = "/home/albi/secrets/cloudflared.env";
            User = "cloudflared";
            Group = "cloudflared";
        };
    };
    users.users.cloudflared = {
        group = "cloudflared";
        isSystemUser = true;
    };
    users.groups.cloudflared = { };

    services.restic = {
        server = {
            enable = true;
            appendOnly = true;
            extraFlags = [ "--no-auth" ];
            listenAddress = "31415";
        };
# backups = {
#     local = {
#         paths = [
#             "/home/albi/secrets/"
#             "/var/lib/backup/"
#             "/var/lib/couchdb/.shards/"
#             "/var/lib/couchdb/shards/"
#             "/var/lib/couchdb/*.couch"
#             "/var/lib/couchdb/local.ini"
#         ];
#         repository = "rest:http://netherite:31415/iron";
#         passwordFile = "/home/albi/secrets/restic.key";
#         initialize = true;
#     };
# };
    };
}
