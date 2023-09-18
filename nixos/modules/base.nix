{ config, lib, pkgs, ... }:
let
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
    nixpkgs.config.allowUnfree = true;

    # nix.nixPath = [ "nixos-config=/home/albi/.config/nixos/hosts/redstone/configuration.nix" ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    imports = [
      (import "${home-manager}/nixos")
    ];

    environment = {
        systemPackages = with pkgs; [
            bottom
            dotnet-sdk_8
            gcc
            git gh
            glow
            go gopls gotools
            lsd
            lua-language-server
            mono
            neofetch
            neovim
            nil
            nodejs
            pstree
            python3
            ripgrep
            rustup
            unzip
            wget
            yt-dlp
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

    users.users.albi = {
        isNormalUser = true;
        description = "Albert Ragány-Németh";
        extraGroups = [ "networkmanager" "wheel" ];
        packages = [ ];
    };
}
