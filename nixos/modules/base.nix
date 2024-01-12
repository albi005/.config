{ config, lib, pkgs, ... }:
let
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
    imports = [
      (import "${home-manager}/nixos")
    ];

    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing (scroll down)
    boot.loader = {
        # Use systemd-boot by default
        systemd-boot.enable = lib.mkDefault true;

        # Set to false when running on garbage
        # https://nixos.wiki/wiki/Bootloader#Installing_x86_64_NixOS_on_IA-32_UEFI
        efi.canTouchEfiVariables = lib.mkDefault true;

        # Update in host config as necessary
        grub.device = lib.mkDefault "/dev/sda";
    };

    # https://nixos.wiki/wiki/NTFS
    boot.supportedFilesystems = [ "ntfs" ];

    # https://nixos.wiki/wiki/Nixos-generate-config
    fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

    environment = {
        # /etc/profile sources /nix/store/*-set-environment
        variables = {
            NIXPKGS_ALLOW_UNFREE = "1";
        };

        systemPackages = with pkgs; [
            bottom
            calc
            dotnet-sdk_8
            exiftool
            gcc
            git gh
            glow
            go gopls gotools
            inetutils
            lsd
            lua-language-server
            mono
            neofetch
            neovim
            nil
            nmap
            nodejs
            onefetch
            pstree
            python3 nodePackages_latest.pyright
            ripgrep
            rustup
            tcpdump
            unzip
            wget
            xclip
            xz
            yt-dlp
            zip
        ];
    };

    programs.nix-ld.enable = true;

    home-manager.users.albi = import ../home.nix;

    networking = {
        networkmanager.enable = true;
        firewall = {
            enable = true;
            trustedInterfaces = [ "tailscale0" ];
        };

        # Cloudflare DNS
        nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
    };

    programs.direnv.enable = true;

    programs.tmux = {
        enable = true;
        keyMode = "vi";
        plugins = [ pkgs.tmuxPlugins.sensible ];
        extraConfig = "set-option -ga terminal-overrides ',alacritty:Tc'";
    };

    services = {
        tailscale.enable = true;
    };

    # Ignore missing disks
    systemd.enableEmergencyMode = false;

    users.users.albi = {
        isNormalUser = true;
        description = "Albert Ragány-Németh";
        extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" ];
        packages = [ ];
    };

    # blank tty after 60 seconds
    boot.kernelParams = [ "consoleblank=60" ];

    # DON'T TOUCH
    system.stateVersion = "23.05";
}
