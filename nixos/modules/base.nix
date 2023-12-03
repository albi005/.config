{ config, lib, pkgs, ... }:
let
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
    nixpkgs.config.allowUnfree = true;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      (import "${home-manager}/nixos")
    ];

    # Bootloader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

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

    system.stateVersion = "23.05";

    systemd.enableEmergencyMode = false;

    users.users.albi = {
        isNormalUser = true;
        description = "Albert Ragány-Németh";
        extraGroups = [ "networkmanager" "wheel" ];
        packages = [ ];
    };
}
