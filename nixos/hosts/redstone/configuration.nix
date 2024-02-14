{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
        ../../modules/hyprland.nix
        ../../modules/nvidia1.nix
    ];

    networking.hostName = "redstone";
    virtualisation.docker.enable = true;

    # https://nixos.wiki/wiki/Nvidia
    # Make sure opengl is enabled
    hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
    };

    # Tell Xorg to use the nvidia driver (also valid for Wayland)
    services.xserver.videoDrivers = ["nvidia"];
    #
    # hardware.nvidia = {
    #     # Modesetting is needed for most Wayland compositors
    #     modesetting.enable = true;
    #
    #     # Use the open source version of the kernel module
    #     # Only available on driver 515.43.04+
    #     open = false;
    #
    #     # Enable the nvidia settings menu
    #     nvidiaSettings = true;
    # };

    services = {
        jellyseerr.enable = true;

        sonarr.enable = true;
        sonarr.group = "media";

        radarr.enable = true;
        radarr.group = "media";

        prowlarr.enable = true;

        jellyfin.enable = true;
        jellyfin.group = "media";

        nginx = {
            enable = true;
            virtualHosts = 
                let listen = [ {
                    addr = "100.74.100.33";
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
                    locations."/".proxyPass = "http://localhost:10069";
                    locations."/".proxyWebsockets = true;
                    inherit listen;
                };
            };
        };
    };
    users.groups.media = {};

    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            sus2 = {
                image = "sus2";
                volumes = [ "/home/albi/www/sus2:/data" ];
                environment = {
                    ConnectionStrings__Database = "Data Source=/data/pings.db";
                    ASPNETCORE_URLS = "http://*:16744";
                };
                extraOptions = [ "--network=host" ];
            };
        };
    };

    services.tailscale.useRoutingFeatures = "both";

    # systemd.services.nzxt = {
    #     description = "NZXT Kraken and Smart Device V1 setup";
    #     wantedBy = [ "default.target" ];
    #     serviceConfig = {
    #         Type = "oneshot";
    #         ExecStart = [
    #             "${pkgs.liquidctl}/bin/liquidctl initialize all"
    #             "${pkgs.liquidctl}/bin/liquidctl --match Kraken set sync color off"
    #             "${pkgs.liquidctl}/bin/liquidctl --match Smart set led color off"
    #         ];
    #     };
    # };

    systemd.targets.sleep.enable = true;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    fileSystems = {
        "/mnt/hdd" = {
            device = "/dev/disk/by-uuid/560AFE250AFE01B3";
            fsType = "ntfs3";
        };
        "/mnt/win11" = {
            device = "/dev/disk/by-uuid/8014EE8214EE7A94";
            fsType = "ntfs3";
        };
    };
}

