{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
    ];

    networking.hostName = "netherite";

    programs.hyprland.enable = true;

    fileSystems = {
        "/mnt/win11" = {
            device = "/dev/disk/by-uuid/64F2AE4CF2AE21F2";
            fsType = "ntfs3";
        };
    };

    virtualisation.docker.enable = true;


    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;
}

