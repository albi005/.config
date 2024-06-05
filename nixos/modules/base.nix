{ config, lib, pkgs, ... }:
let
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
    imports = [
      (import "${home-manager}/nixos")
      ./neovim.nix
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
            cava #tui audio visualizer
            cloc #Count Lines Of Code
            cmatrix #Matrix like effect in your terminal
            dotnet-sdk_8
            dua #Disk Usage Analyzer tui
            exiftool
            fastfetch
            fd
            file #file info
            gcc
            git gh
            glow
            gnumake #make
            go gopls gotools
            inetutils
            iperf
            jq #command-line JSON processor
            lsd
            lua-language-server
            mono
            netscanner #nmap tui
            nil
            nixd
            nixfmt-rfc-style
            nmap
            nodejs
            onefetch
            pstree
            python3
            restic
            ripgrep
            rustup
            sl
            smartmontools
            sqlcmd
            systemctl-tui
            tcpdump
            typescript
            unzip
            wget
            xclip
            xz
            yarn
            yt-dlp
            zip
            zoxide
        ];
    };

    programs.bash.shellInit = ''
        # https://github.com/ajeetdsouza/zoxide#installation
        eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    '';
    programs.nix-ld.enable = true;
    programs.java.enable = true;

    networking = {
        networkmanager.enable = true;
        firewall = {
            enable = true;
            trustedInterfaces = [ "tailscale0" ];
        };

        # Cloudflare DNS
        nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
    };

    # https://discourse.nixos.org/t/19963/2
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;

    programs.direnv.enable = true;

    programs.tmux = {
        enable = true;
        keyMode = "vi";
        plugins = with pkgs.tmuxPlugins; [
            sensible
            catppuccin
        ];
        extraConfig = ''
            set-option -ga terminal-overrides ',alacritty:Tc'

            #https://wezfurlong.org/wezterm/shell-integration.html#user-vars
            set -g allow-passthrough on
        '';
    };

    services.tailscale.enable = true;

    # Ignore missing disks
    systemd.enableEmergencyMode = false;

    users.users.albi = {
        isNormalUser = true;
        description = "Albert Ragány-Németh";
        extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" ];
        packages = [ ];
    };
    home-manager.users.albi = import ./base.home.nix;

    services.journald.extraConfig = ''
        SystemMaxUse=100M
    '';

    # blank tty after 60 seconds
    boot.kernelParams = [ "consoleblank=60" ];

    # DON'T TOUCH
    system.stateVersion = "23.05";
}
