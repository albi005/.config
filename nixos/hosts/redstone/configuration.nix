{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
    ];

    networking.hostName = "redstone";

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # https://nixos.wiki/wiki/Nvidia
    # Make sure opengl is enabled
    hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
    };

    # Tell Xorg to use the nvidia driver (also valid for Wayland)
    services.xserver.videoDrivers = ["nvidia"];

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
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

    services.tailscale.useRoutingFeatures = "both";

    systemd.services.nzxt = {
        description = "NZXT Kraken and Smart Device V1 setup";
        wantedBy = [ "default.target" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = [
                "${pkgs.liquidctl}/bin/liquidctl initialize all"
                "${pkgs.liquidctl}/bin/liquidctl --match Kraken set sync color off"
                "${pkgs.liquidctl}/bin/liquidctl --match Smart set led color off"
            ];
        };
    };

    fileSystems = {
        "/mnt/hdd" = {
            device = "/dev/disk/by-uuid/560AFE250AFE01B3";
            fsType = "ntfs3";
        };
        "/mnt/popos" = {
            device = "/dev/disk/by-uuid/cd8454ca-b374-43b4-8285-570e3216a6fa";
            fsType = "ext4";
        };
        "/mnt/win11" = {
            device = "/dev/disk/by-uuid/8014EE8214EE7A94";
            fsType = "ntfs3";
        };
    };

    hardware.nvidia = {
        # Modesetting is needed for most Wayland compositors
        modesetting.enable = false;

        # Use the open source version of the kernel module
        # Only available on driver 515.43.04+
        open = false;

        # Enable the nvidia settings menu
        nvidiaSettings = false;
    };
}

