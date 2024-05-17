{ config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ../../modules/base.nix
        ../../modules/desktop.nix
    ];

    networking.hostName = "netherite";

    users.users.albi.packages = with pkgs; [
        jetbrains.clion
        jetbrains.idea-ultimate
    ];
}
