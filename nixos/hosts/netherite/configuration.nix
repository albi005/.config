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

    users.users.mssql = {
        isSystemUser = true;
        group = "mssql";
    };
    users.groups.mssql = {
    };

    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

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
}

