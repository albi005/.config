{ config, pkgs, ... }:
{
    networking.hostName = "iron";

    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../pkgs/qbittorrent.nix
    ];

    virtualisation.docker.enable = true;

    services.vaultwarden = {
        enable = true;
        config = {
            DOMAIN = "https://p.alb1.hu";
            SIGNUPS_ALLOWED = true;
            ROCKET_ADDRESS = "127.0.0.1";
            ROCKET_PORT = 10003;
        };
    };

    services.couchdb = {
        enable = true;
        port = 10004;
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

    systemd.services.alb1 = {
        description = "alb1.hu";
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig =
        let
            package = pkgs.callPackage ../../pkgs/alb1.hu/default.nix { };
        in
        {
            ExecStart = "${package}/bin/Hello --urls=http://localhost:10001";
        };
    };

    systemd.services.wakapi = {
        description = "Wakapi";
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
# https://github.com/muety/wakapi/blob/master/etc/wakapi.service
            ExecStart = "${pkgs.wakapi}/bin/wakapi";
            WorkingDirectory = "/var/lib/wakapi";
            StateDirectory = "wakapi";
            StateDirectoryMode = "0700";
            User = "wakapi";
            Group = "wakapi";

            PrivateTmp = "true";
            PrivateUsers = "true";
            NoNewPrivileges = "true";
            ProtectSystem = "full";
            ProtectHome = "true";
            ProtectKernelTunables = "true";
            ProtectKernelModules = "true";
            ProtectKernelLogs = "true";
            ProtectControlGroups = "true";
            PrivateDevices = "true";
            CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
            ProtectClock = "true";
            RestrictSUIDSGID = "true";
            ProtectHostname = "true";
            ProtectProc = "invisible";
        };
    };
    users.users.wakapi = {
        group = "wakapi";
        isSystemUser = true;
    };
    users.groups.wakapi = { };

# https://github.com/vogler/free-games-claimer
# sudo docker run --rm -it -p 6080:6080 -v fgc:/fgc/data --pull=always ghcr.io/vogler/free-games-claimer node epic-games
# noVNC at http://iron:6080
    services.cron = {
        enable = true;
        systemCronJobs = [
            "0 3 * * * docker run --rm -it -p 6080:6080 -v fgc:/fgc/data --pull=always ghcr.io/vogler/free-games-claimer node epic-games"
        ];
    };


    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            menza = {
                image = "menza";
                volumes = [ "/home/albi/www/Menza:/data" ];
                environment = {
                    ASPNETCORE_ENVIRONMENT = "Production";
                    ConnectionStrings__Database="Data Source=/data/menza.db";
                    Firebase__ServiceAccount="/data/service-account.json";
                };
                environmentFiles = [ /home/albi/secrets/menza.env ];
                ports = [ "10002:80" ];
            };
            dishelps = {
                image = "dishelps";
                volumes = [ "/home/albi/www/DisHelps:/data" ];
                environment = {
                    ASPNETCORE_ENVIRONMENT = "Production";
                    ConnectionStrings__Database = "Data Source=/data/dishelps.db";
                };
                ports = [ "10005:8080" ];
            };
            keletikuria = {
                image = "keletikuria";
                volumes = [ "/home/albi/www/KeletiKuria:/data" ];
                environment = {
                    ASPNETCORE_ENVIRONMENT = "Production";
                    ConnectionStrings__Database = "Data Source=/data/keletikuria.db";
                };
                environmentFiles = [ /home/albi/secrets/keletikuria.env ];
                ports = [ "10006:8080" ];
            };
        };
    };

    services = {
        # jellyseerr.enable = true;
        #
        # sonarr.enable = true;
        # sonarr.group = "media";
        #
        # radarr.enable = true;
        # radarr.group = "media";
        #
        # prowlarr.enable = true;
        #
        # jellyfin.enable = true;
        # jellyfin.group = "media";
        #
        # qbittorrent.enable = true;
        # qbittorrent.group = "media";

        nginx = {
            enable = true;
            virtualHosts = 
                let listen = [ {
                    addr = "100.99.26.122";
                    port = 80;
                    ssl = false;
                } ];
            in
            {
                "waka.alb1.hu" = {
                    locations."/".proxyPass = "http://localhost:10010";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
            };
        };
    };

    services.tailscale.useRoutingFeatures = "both";

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    users.users.albi.extraGroups = [ "couchdb" ];
    users.groups.media = { };
}
