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

    # https://nixos.wiki/wiki/Bootloader
    boot.loader = {
        # Use systemd-boot by default, but GRUB is needed on systems running BIOS instead of UEFI
        # TODO: Check if this actually works
        systemd-boot.enable = !config.boot.loader.grub.enable;

        # Set to false when running on garbage
        # https://nixos.wiki/wiki/Bootloader#Installing_x86_64_NixOS_on_IA-32_UEFI
        efi.canTouchEfiVariables = lib.mkDefault true;

        # Might want to change this
        grub.device = lib.mkDefault "/dev/sda";
    };

    # https://nixos.wiki/wiki/NTFS
    boot.supportedFilesystems = [ "ntfs" ];

    # https://nixos.wiki/wiki/Nixos-generate-config
    fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

    environment = {
        systemPackages = with pkgs; [
            bottom
            calc
            dotnet-sdk_8
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
            pstree
            python3 nodePackages_latest.pyright
            ripgrep
            rustup
            unzip
            wget
            xclip
            yt-dlp
            zip
        ];

# /etc/profile sources /nix/store/*-set-environment
        variables = {
            EDITOR = "nvim";
            VISUAL = "nvim";
            BROWSER = "google-chrome";
            TERM = "alacritty";
            TERMINAL = "alacritty";
            NIXPKGS_ALLOW_UNFREE = "1";
        };
    };

    home-manager.users.albi = import ../home.nix;

    networking = {
        networkmanager.enable = true;
        firewall = {
            enable = true;
            trustedInterfaces = [ "tailscale0" ];
        };
    };

    programs.direnv.enable = true;
    programs.tmux = {
        enable = true;
        keyMode = "vi";
        plugins = with pkgs.tmuxPlugins; [ sensible ];
        extraConfig = "set-option -ga terminal-overrides ',alacritty:Tc'";
    };

    services = {
        tailscale.enable = true;
        openssh.enable = true;
    };

    # Ignore missing disks
    systemd.enableEmergencyMode = false;

    users.users.albi = {
        isNormalUser = true;
        description = "Albert Ragány-Németh";
        extraGroups = [ "networkmanager" "wheel" ];
        packages = [ ];
    };

    # blank tty after 60 seconds
    boot.kernelParams = [ "consoleblank=60" ];

    # DON'T TOUCH
    system.stateVersion = "23.05";
}
