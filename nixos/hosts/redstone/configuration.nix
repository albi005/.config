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

    users.users.albi.packages = with pkgs; [
        jetbrains.clion
        jetbrains.idea-ultimate
    ];

    services = {
        restic = {
            backups = {
                netherite = {
                    backupPrepareCommand = ''
                        rm -fr /var/lib/backup
                        install -d -m 700 -o root -g root /var/lib/backup
                        cd /var/lib/backup

                        mkdir -p sus2
                        ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/sus2/pings.db ".backup 'sus2/pings.db'"
                    '';

                    paths = [
                        "/home/albi/secrets/"
                        "/var/lib/backup/"
                    ];
                    repository = "rest:http://netherite:31415/redstone";
                    passwordFile = "/home/albi/secrets/restic.key";
                    initialize = true;
                };
            };
        };
    };

    # virtualisation.oci-containers = {
    #     backend = "docker";
    #     containers = {
    #         sus2 = {
    #             image = "sus2";
    #             volumes = [ "/home/albi/www/sus2:/data" ];
    #             environment = {
    #                 ConnectionStrings__Database = "Data Source=/data/pings.db";
    #                 ASPNETCORE_URLS = "http://*:16744";
    #             };
    #             extraOptions = [ "--network=host" ];
    #         };
    #     };
    # };

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

    systemd.targets.sleep.enable = true;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    fileSystems = {
        # "/mnt/hdd" = {
        #     device = "/dev/disk/by-uuid/560AFE250AFE01B3";
        #     fsType = "ntfs3";
        # };
        "/mnt/win11" = {
            device = "/dev/disk/by-uuid/8014EE8214EE7A94";
            fsType = "ntfs-3g";
        };
    };
}

