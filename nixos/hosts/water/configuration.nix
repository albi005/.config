{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
      ../../modules/desktop.nix
      ../../modules/hyprland.nix
    ];

    networking.hostName = "water"; # Define your hostname.
    networking.networkmanager.wifi.macAddress = "permanent";

    environment.systemPackages = with pkgs; [
        cloudflare-warp
    ];

    home-manager.users.albi = { ... }: {
        home.file.".config/hypr/host.conf".text = ''
            input {
                kb_options = caps:swapescape
            }
        '';
    };
}
