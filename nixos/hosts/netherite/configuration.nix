{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
        ../../pkgs/qbittorrent.nix
    ];

    networking.hostName = "netherite";

    programs.hyprland.enable = true;

    fileSystems = {
        "/mnt/win11" = {
            device = "/dev/disk/by-uuid/64F2AE4CF2AE21F2";
            fsType = "ntfs3";
        };
    };

    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    users.users.mssql = {
        isSystemUser = true;
        group = "mssql";
    };
    users.groups.mssql = {};

    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            dfv = {
                image = "mcr.microsoft.com/mssql/server:2022-latest";
                volumes = [
                    "/home/albi/Desktop/dfvdb/data:/var/opt/mssql/data"
                    "/home/albi/Desktop/dfvdb/log:/var/opt/mssql/log"
                    "/home/albi/Desktop/dfvdb/secrets:/var/opt/mssql/secrets"
                ];
                user = "root";
                environment = {
                    ACCEPT_EULA = "Y";
                    MSSQL_SA_PASSWORD = "<YourStrong!Passw0rd>";
                };
                ports = [ "1433:1433" ];
            };
        };
    };

    services = {
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
                    locations."/".proxyPass = "http://localhost:8080";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
            };
        };
    };
    users.groups.media = {
        gid = 989;
    };
}

