{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
      ../../modules/desktop.nix
    ];

    networking.hostName = "water"; # Define your hostname.
    networking.networkmanager.wifi.macAddress = "permanent";
    networking.networkmanager.enable = lib.mkForce false;
    networking.wireless.iwd.enable = true; # no deps wifi daemon
    virtualisation.docker.enable = true;

    environment.systemPackages = with pkgs; [
        impala # tui for iwd
        jetbrains.idea-ultimate
    ];

    # use function keys instead of media keys by default
    # https://wiki.archlinux.org/title/Apple_Keyboard
    boot.extraModprobeConfig = ''
        options hid_apple fnmode=2
    '';

    home-manager.users.albi = { ... }: {
        home.file.".config/hypr/host.conf".text = ''
            input {
                kb_options = caps:swapescape
            }
        '';
    };
}
