{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
      ../../modules/desktop.nix
    ];

    networking.hostName = "water"; # Define your hostname.
    networking.networkmanager.wifi.macAddress = "permanent";

    environment.systemPackages = with pkgs; [
        prismlauncher
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
