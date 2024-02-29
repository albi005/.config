{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
        ../../modules/hyprland.nix
        ../../pkgs/qbittorrent.nix
    ];

    networking.hostName = "netherite";

    fileSystems = {
        "/mnt/win11" = {
            device = "/dev/disk/by-uuid/64F2AE4CF2AE21F2";
            fsType = "ntfs-3g";
        };
    };

    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    services = {
        restic = {
            server = {
                enable = true;
                appendOnly = true;
                extraFlags = [ "--no-auth" ];
                listenAddress = "100.118.32.33:31415";
                prometheus = true; # TODO: idk
            };
        };

        jellyseerr.enable = true;

        sonarr.enable = true;
        sonarr.group = "media";

        radarr.enable = true;
        radarr.group = "media";

        prowlarr.enable = true;

        jellyfin.enable = true;
        jellyfin.group = "media";

        qbittorrent.enable = true;
        qbittorrent.group = "media";
        qbittorrent.port = 9797;

        nginx = {
            enable = true;
            virtualHosts = 
                let listen = [ {
                    addr = "100.118.32.33";
                    port = 80;
                    ssl = false;
                } ];
            in
            {
                "jellyseer.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:5055";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
                "sonarr.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:8989";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
                "radarr.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:7878";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
                "prowlarr.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:9696";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
                "jellyfin.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:8096";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
                "torrent.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:9797";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
            };
        };
    };
    users.groups.media = {
        gid = 989;
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
}

