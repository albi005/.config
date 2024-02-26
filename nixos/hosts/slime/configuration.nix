{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
    ];

    networking.hostName = "slime";
    
    users.users.a = {
        isNormalUser = true;
        createHome = false;
    };

    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            dfv = {
                image = "mcr.microsoft.com/mssql/server:2022-latest";
                volumes = [
                    "/var/lib/dfvdb/data:/var/opt/mssql/data"
                    "/var/lib/dfvdb/log:/var/opt/mssql/log"
                    "/var/lib/dfvdb/secrets:/var/opt/mssql/secrets"
                ];
                user = "root";
                environment = {
                    ACCEPT_EULA = "Y";
                    MSSQL_SA_PASSWORD = "<YourStrong!Passw0rd>";
                };
                ports = [ "192.168.0.82:1433:1433" "100.67.9.2:1433:1433" ];
            };
        };
    };
    systemd.services.docker-dfv = {
        wants = [ "tailscaled.service" ];
        after = [ "tailscaled.service" ];
    };

    services.openssh.enable = true;

    services.vsftpd.enable = true;
    services.vsftpd.writeEnable = true;
    services.vsftpd.localUsers = true;

    fileSystems = {
        "/shared/Laptop" = {
            device = "/dev/disk/by-uuid/18086CF45A9D036C";
            fsType = "ntfs-3g";
        };
    };

    # https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server
    services.samba = {
        enable = true;
        shares = {
            Megosztott = {
                path = "/shared/Megosztott";
                "writeable" = "yes";
                "create mask" = "0770";
                "directory mask" = "0770";
            };
            Kozos = {
                path = "/shared/Kozos";
                "writeable" = "yes";
                "create mask" = "0770";
                "directory mask" = "0770";
            };
            Laptop = {
                path = "/shared/Laptop";
                "writeable" = "no";
            };
        };
    };

    power.ups = {
        enable = true;
        ups.main = {
            port = "auto";
            driver = "usbhid-ups";
            description = "The singular PSU connected";
        };
        upsmon.monitor.main = {
            system = "main";
            user = "main";
            passwordFile = "why";
        };
    };

    system.autoUpgrade = {
        enable = true;
        channel = "nixos-unstable";
        flags = [ "-I" "nixos-config=/home/albi/.config/nixos/hosts/$HOSTNAME/configuration.nix" ];
        dates = "03:00";
        allowReboot = true;
        rebootWindow = {
            lower = "01:00";
            upper = "05:00";
        };
        randomizedDelaySec = "45min";
    };

    nix.gc = {
        automatic = true;
        dates = "03:30";
        options = "--delete-older-than 30d";
        randomizedDelaySec = "45min";
    };
}
