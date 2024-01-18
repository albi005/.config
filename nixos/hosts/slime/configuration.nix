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
                ports = [ "100.67.9.2:1433:1433" ];
            };
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
