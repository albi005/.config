{ config, lib, pkgs, ... }:

{
    imports = [

    ];

    environment.variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
    };

    environment.systemPackages = with pkgs; [
        bottom
        dotnet-sdk_8
        gcc
        git gh
        go gopls gotools
        lsd
        lua-language-server
        neofetch
        neovim
        nil
        nodejs
        pstree
        python3
        ripgrep
        rustup rust-analyzer
        tmux
        unzip
        wget
        yt-dlp
    ];
}
