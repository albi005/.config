{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
    ];

    networking.hostName = "slime1";

    boot.loader.systemd-boot.enable = false;

    services.vsftpd.enable = true;
    services.vsftpd.writeEnable = true;
    services.vsftpd.localUsers = true;

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
