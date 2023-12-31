{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
    ];

    networking.hostName = "slime";

    boot.loader.systemd-boot.enable = false;
}
